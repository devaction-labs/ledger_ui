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
  accordion accordion-item accordion-header accordion-chevron accordion-body
  collapse collapse-trigger collapse-chevron collapse-panel collapse-text collapse-text-body collapse-more
  palette palette-overlay palette-search palette-input palette-kbd palette-scopes palette-scope palette-list palette-label palette-item palette-avatar palette-sub palette-keys palette-count palette-footer palette-hint palette-spacer
  drawer drawer-overlay drawer-header drawer-heading drawer-title drawer-description drawer-close drawer-body drawer-footer drawer-grab
  modal modal-overlay modal-header modal-heading modal-title modal-description modal-close modal-body modal-footer
  notification-center notification-bell notification-badge notification-float notification-panel notification-header notification-tabs notification-tab notification-read-all notification-group notification-item notification-dot notification-text notification-time notification-avatar notification-body notification-title notification-footer notification-link notification-empty-icon notification-heading notification-spacer notification-tabs-wrap notification-tab-badge notification-unread notification-text-body notification-at notification-empty-title notification-empty-text notification-strong
  popover popover-float popover-card popover-title
  tooltip tooltip-float tooltip-tip
)
