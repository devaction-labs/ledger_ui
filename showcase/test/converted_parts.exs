# `data-part` names of the elements of components already MIGRATED to Tailwind utilities.
# For these elements the parity tests ignore `class` (see LedgerShowcase.Parity, "CONVERTED PARTS"):
# they are checked by `python parity/run.py` (pixels) instead. A batch adds ITS parts here, one line per
# component (this is the only shared file a batch edits in showcase/test; add lines, never reorder).
~w(
  button button-spinner button-pip button-group icon-button insight-button insight-button-count
  badge badge-dot badge-remove
  card card-title card-header card-heading card-subheading card-body card-footer card-actions card-bleed
  icon-box
  input input-control input-addon password-toggle
  field label label-row label-required label-optional label-hint field-body field-row error help
  stat stat-group stat-label stat-value stat-unit stat-hint stat-foot stat-delta stat-arrow stat-meter stat-meter-bar stat-spark stat-spark-svg stat-spark-area stat-spark-line stat-spark-dot
  palette palette-step palette-chip palette-swatch palette-color palette-meta palette-name palette-token palette-values
  clipboard clipboard-label clipboard-input clipboard-input-addon
  divider divider-line divider-label
  fab fab-label fab-badge fab-tile fab-dial fab-dial-button fab-dial-menu fab-dial-item fab-dial-label
  illustration illustration-card illustration-line illustration-badge empty-box
  heading text text-link inline-code kbd
  alert alert-icon alert-text alert-title alert-description alert-close
  aura
  connection-banner
  empty-state empty-state-art empty-state-ring empty-state-kicker empty-state-title empty-state-text empty-state-disc
  error-page error-header error-brand error-status error-status-dot error-body error-main error-heading error-code error-label error-title error-description error-actions error-back error-art error-numeral error-card error-footer error-request error-request-id error-copy error-timestamp error-links-footer error-state error-state-code error-state-title error-state-description error-state-actions error-state-more error-links error-links-title error-link error-link-text error-link-description
  progress progress-bar progress-stack progress-segment
  skeleton skeleton-group skeleton-label
  spinner spinner-icon
  toaster toast-stack toast-card toast-aura toast-fill toast-tile toast-body toast-title toast-description toast-close toast-pct status-toast status-toast-lead status-toast-liquid status-toast-dot status-toast-msg status-toast-action
)
