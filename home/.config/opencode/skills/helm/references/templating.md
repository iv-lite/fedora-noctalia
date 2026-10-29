# Templating

## Context objects

| Object | Contains |
| --- | --- |
| `.Values` | Merged chart and user values |
| `.Release` | `Name`, `Namespace`, `Service`, `Revision`, `IsInstall`, `IsUpgrade` |
| `.Chart` | `Name`, `Version`, `AppVersion`, `Annotations` |
| `.Capabilities` | `KubeVersion`, `APIVersions`, `HelmVersion` |
| `.Files` | Non-template files in the chart |
| `.Template` | `Name`, `BasePath` |

## Helpers

Define reusable names in `templates/_helpers.tpl`:

```gotemplate
{{- define "api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "api.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "api.labels" -}}
app.kubernetes.io/name: {{ include "api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
```

Use `include` when the result is needed as a string (it can be piped to `nindent`).
`template` writes directly and cannot be piped.

```yaml
metadata:
  name: {{ include "api.fullname" . }}
  labels:
    {{- include "api.labels" . | nindent 4 }}
```

## Whitespace

- `{{-` trims preceding whitespace; `-}}` trims following whitespace.
- Use `nindent N` to add a newline plus indentation; use `indent N` to indent without a
  leading newline.
- Incorrect whitespace is the most common cause of invalid YAML.

```yaml
spec:
  template:
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

## Values handling

```gotemplate
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- $port := .Values.service.port | int -}}
```

- `default` treats empty strings, zero, false, and nil as empty.
- `required "message" .Values.foo` fails rendering when the value is missing or empty.
- `quote` is important for values that look like numbers or booleans.
- `toString`, `int`, `float64`, and `bool` convert types explicitly.
- `coalesce` returns the first non-empty value.
- `ternary "yes" "no" (eq .Values.mode "prod")` selects between two values.
- `dig` safely reads nested maps; `get`/`hasKey` are useful for optional maps.

## Control flow

```gotemplate
{{- if .Values.ingress.enabled }}
...
{{- end }}

{{- range $name, $config := .Values.workers }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "api.fullname" $ }}-{{ $name }}
{{- end }}
```

- Inside `range`, `$` refers to the root context. Capture it before nested scopes:
  `{{- $root := . -}}`.
- `with` changes `.` to the value when non-empty.
- `else if` and `else` are supported.
- Use `{{- /* comment */ -}}` for template comments; they do not render.

## YAML and files

- `toYaml` serializes a value; pair it with `nindent`.
- `toJson` is useful for annotations or embedded JSON.
- `fromYaml`, `fromJson`, `fromYamlArray` parse data.
- `.Files.Get "config/app.conf"` reads a chart file.
- `.Files.Glob "config/*.conf"` and `.AsConfig` build ConfigMaps.
- Use `b64enc` for Secret data, but do not treat base64 as encryption.

## Cluster-aware templates

- `lookup "v1" "Secret" .Release.Namespace "name"` queries the cluster during install or
  upgrade. It returns empty during `helm template` and may fail in offline rendering.
- `.Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget"` gates resources by API
  availability.
- `semverCompare ">=1.28-0" .Capabilities.KubeVersion.Version` gates by cluster version.
- Avoid branching on cluster state when a declarative field would work.

## Determinism

- Do not use `randAlphaNum`, `randAscii`, `uuidv4`, or `now` for resource names,
  checksums, or passwords; every render changes.
- If a random value is required, generate it outside Helm and pass it as a value.
- Sort maps when order matters; Go map iteration is not stable.
- Pin subchart versions and keep `Chart.lock`.
- `helm template` output should be identical across repeated runs with the same inputs.

## Validation in templates

- Use `required` for values that must be set.
- Use `fail "message"` for invalid combinations.
- Validate mutually exclusive settings explicitly.
- Keep validation messages actionable: name the value and expected shape.
