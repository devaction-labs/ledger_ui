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
  tabs tabs-list tab tab-count tabs-panels tabs-panel
  breadcrumb breadcrumb-link breadcrumb-current breadcrumb-text breadcrumb-separator breadcrumb-more
  pagination pagination-page pagination-arrow pagination-ellipsis pagination-link pagination-button pagination-footer pagination-summary pagination-spacer pagination-size
  steps step step-marker step-label step-sub step-line
  menu-list menu-item menu-item-count menu-rows menu-row menu-row-body menu-row-title menu-row-sub menu-row-unread
  scrollspy scrollspy-link
  view-switcher view-switcher-seg view-switcher-view view-switcher-count view-switcher-saved view-switcher-add view-switcher-grid
  dropdown dropdown-menu dropdown-toggle dropdown-kebab dropdown-split dropdown-action dropdown-submenu pop pop-item pop-item-text pop-item-hint pop-separator pop-label pop-head pop-head-title pop-head-subtitle pop-search pop-search-input pop-foot pop-end pop-kbd pop-check
  action-menu action-menu-trigger action-menu-panel action-button
  context-menu
)
