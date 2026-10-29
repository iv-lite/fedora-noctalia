# Controller patterns

## Reconcile shape

```go
func (r *DatabaseReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := logf.FromContext(ctx)

    var db examplev1.Database
    if err := r.Get(ctx, req.NamespacedName, &db); err != nil {
        if apierrors.IsNotFound(err) {
            return ctrl.Result{}, nil
        }
        return ctrl.Result{}, err
    }

    if !db.DeletionTimestamp.IsZero() {
        return r.reconcileDelete(ctx, &db)
    }

    if err := r.reconcileNormal(ctx, &db); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{}, nil
}
```

- Reconcile is level-triggered: derive desired state from the current object and cluster
  state, not from the event that triggered it.
- Handle deletion before normal reconciliation.
- Treat `NotFound` as success.
- Keep the function idempotent; it may run many times for the same state.
- Do not assume ordering between events or resources.

## Owned resources

- Set owner references for resources owned by the custom resource:

  ```go
  if err := controllerutil.SetControllerReference(db, deploy, r.Scheme); err != nil {
      return err
  }
  ```

- Owner references only work within the same namespace. Cross-namespace resources need
  explicit cleanup and a finalizer.
- Watch owned resources so their changes trigger reconciliation:

  ```go
  func (r *DatabaseReconciler) SetupWithManager(mgr ctrl.Manager) error {
      return ctrl.NewControllerManagedBy(mgr).
          For(&examplev1.Database{}).
          Owns(&appsv1.Deployment{}).
          Owns(&corev1.Service{}).
          Complete(r)
  }
  ```

- Use `Watches` with a mapping function for resources that are not directly owned.
- Add predicates to ignore irrelevant updates, but do not filter out changes the
  controller depends on (for example, generation changes or deletion).

## Create or update

- Prefer server-side apply for declarative desired state when the project supports it.
- Otherwise use `controllerutil.CreateOrUpdate` or explicit get/create/update.
- Always set the desired fields you own; do not blindly overwrite fields owned by other
  controllers.
- On update conflicts, return the error or retry with a fresh read. Do not loop forever
  inside a single reconcile.
- Preserve user-managed annotations and labels unless they are part of your contract.
- Do not mutate the cached object in place; work on a deep copy.

## Status updates

- Update status with `r.Status().Update` or a status patch.
- Do not update spec in the same call as status.
- Re-read if a conflict occurs, then recompute the condition.
- Update status even on failure, so users can see why reconciliation did not succeed.
- Avoid updating status when nothing changed; it causes write amplification.
- Use `observedGeneration` to indicate which spec generation the status reflects.

## Finalizers

```go
const finalizer = "example.com/database-cleanup"

if db.DeletionTimestamp.IsZero() {
    if controllerutil.AddFinalizer(&db, finalizer) {
        return ctrl.Result{}, r.Update(ctx, &db)
    }
} else if controllerutil.ContainsFinalizer(&db, finalizer) {
    if err := r.cleanupExternal(ctx, &db); err != nil {
        return ctrl.Result{}, err
    }
    controllerutil.RemoveFinalizer(&db, finalizer)
    return ctrl.Result{}, r.Update(ctx, &db)
}
```

- Add a finalizer only if the controller must clean up external state.
- Add it before creating external resources so deletion cannot race creation.
- Cleanup must be idempotent and safe to retry.
- Never remove the finalizer until cleanup succeeded.
- Make it possible to force-remove a stuck finalizer manually, and document the risk.
- Do not use finalizers for simple owned resources; owner references handle those.

## Errors and requeueing

- Return an error for transient failures; controller-runtime applies rate-limited
  backoff.
- Return `Requeue: true` sparingly; prefer `RequeueAfter` for known delays.
- Do not requeue terminal validation failures forever without surfacing a condition.
- Distinguish "not ready yet" from "broken".
- Wrap errors with context: `fmt.Errorf("create deployment: %w", err)`.
- Emit Events for user-visible state changes and failures.

## Watches and predicates

- `For` watches the primary resource.
- `Owns` watches owned resources and maps them to the owner.
- `Watches` with `handler.EnqueueRequestsFromMapFunc` maps arbitrary resources.
- Use `predicate.GenerationChangedPredicate` for spec-only changes, but remember status
  updates and deletions.
- Do not ignore annotation-only changes if annotations affect behavior.
- Watch only what you need; each watch adds cache memory and API load.

## Concurrency and leadership

- Set `MaxConcurrentReconciles` deliberately; default is one.
- Use leader election when multiple replicas run.
- Ensure reconciliation is safe if two replicas briefly overlap during leader changes.
- Use a namespace-scoped cache when the operator is namespaced.
- Bound work per reconcile to avoid long-running loops.

## Long-running work

- Use Jobs for builds, migrations, and batch tasks.
- Track Job status and surface progress in conditions.
- Clean up completed Jobs according to a retention policy.
- Do not block a reconcile on a multi-minute operation; requeue and observe.

## Logging and events

- Log with `logf.FromContext(ctx)` and structured keys:

  ```go
  log.Info("reconciled database", "name", db.Name, "namespace", db.Namespace)
  ```

- Do not log full specs or secrets.
- Emit Events for user-facing transitions: created, updated, failed, ready.
- Avoid duplicate Events on every reconcile; emit on state changes.
