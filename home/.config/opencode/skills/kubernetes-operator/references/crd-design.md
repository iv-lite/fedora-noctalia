# CRD and API design

## Group, version, kind

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.example.com
spec:
  group: example.com
  scope: Namespaced
  names:
    kind: Database
    listKind: DatabaseList
    plural: databases
    singular: database
    shortNames: [db]
    categories: [all]
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
            status:
              type: object
```

- Use a stable, owned API group. Do not reuse another project's group.
- `plural` is the resource name used by `kubectl get`.
- `scope: Namespaced` is the default choice; use `Cluster` only when the object must be
  cluster-wide.
- `categories: [all]` makes resources appear in `kubectl get all`; use deliberately.
- Exactly one version must have `storage: true`.

## Spec and status

```go
type DatabaseSpec struct {
    Engine   string        `json:"engine"`
    Version  string        `json:"version"`
    Replicas int32         `json:"replicas,omitempty"`
}

type DatabaseStatus struct {
    ObservedGeneration int64              `json:"observedGeneration,omitempty"`
    Conditions         []metav1.Condition `json:"conditions,omitempty"`
    ReadyReplicas      int32              `json:"readyReplicas,omitempty"`
}
```

- `spec` is user intent. Keep it declarative and free of controller-generated values.
- `status` is observed state. It must be reconstructible by the controller.
- Use `metav1.Condition` for conditions, not a custom boolean soup.
- Always include `observedGeneration` so users know whether status reflects the latest
  spec.
- Mark optional fields with `omitempty`; avoid pointers unless you need to distinguish
  zero from unset.
- Do not put large payloads, logs, or secrets in status.

## Validation

- Add OpenAPI validation in the CRD schema: required fields, enums, minimum/maximum,
  patterns, and string length limits.
- Use CEL for cross-field rules:

  ```yaml
  x-kubernetes-validations:
    - rule: "self.replicas >= 1"
      message: "replicas must be at least 1"
  ```

- Validate at the API boundary, not only in the controller. Invalid objects should be
  rejected or flagged before reconciliation.
- Use admission webhooks for validation that needs cluster state or complex logic.
- Prefer CRD schema validation over webhooks when possible; it is simpler and more
  reliable.
- Default fields in the schema when defaults are safe; otherwise default in the
  controller and record it in status.

## Status conditions

Use standard condition types and reasons:

```go
meta.SetStatusCondition(&db.Status.Conditions, metav1.Condition{
    Type:               "Ready",
    Status:             metav1.ConditionTrue,
    Reason:             "ReconcileSucceeded",
    Message:            "Database is ready",
    ObservedGeneration: db.Generation,
})
```

- Common condition types: `Ready`, `Progressing`, `Degraded`, `Available`.
- `Reason` should be a short CamelCase token; `Message` should be actionable.
- Never leave a stale `Ready=True` after a failure; update conditions on every path.
- Do not use conditions as a substitute for detailed status fields.

## Printer columns and subresources

```yaml
additionalPrinterColumns:
  - name: Engine
    type: string
    jsonPath: .spec.engine
  - name: Ready
    type: string
    jsonPath: .status.conditions[?(@.type=="Ready")].status
  - name: Age
    type: date
    jsonPath: .metadata.creationTimestamp
subresources:
  status: {}
  scale:
    specReplicasPath: .spec.replicas
    statusReplicasPath: .status.readyReplicas
```

- Enable the status subresource so spec and status updates do not conflict.
- Add the scale subresource only when horizontal scaling semantics are meaningful.
- Printer columns should show the most useful operational state, not every field.

## List types and merge semantics

- For maps and lists that are merged by multiple controllers, set
  `x-kubernetes-list-type`, `x-kubernetes-list-map-keys`, or `x-kubernetes-map-type`.
- Lists default to atomic replacement; use `set` or `map` only when merge behavior is
  intended.
- Be cautious with server-side apply and list fields; conflicting managers can fight.

## Versioning and conversion

- Start with `v1alpha1` for unstable APIs, `v1beta1` for near-stable, `v1` for stable.
- Never remove or change the type of an existing field in a served version. Add a new
  field or a new version.
- Only one version is the storage version.
- Conversion webhooks translate between hub and spoke versions. The hub version usually
  implements `ConvertTo`/`ConvertFrom`.
- Test round-trip conversion and loss of unknown fields.
- Plan storage-version migration before changing `storage: true`.
- Deprecate fields and versions with clear documentation and a migration path.

## Naming and limits

- CRD names must be `<plural>.<group>`.
- Keep schema size reasonable; CRDs have API size limits.
- Use structural schemas. Avoid `preserveUnknownFields: true` unless you have a specific
  reason.
- Field names are part of the API; use lowerCamelCase JSON names.
- Document every field with comments that translate into schema descriptions.
