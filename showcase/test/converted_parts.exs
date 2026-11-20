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
  accordion accordion-item accordion-header accordion-chevron accordion-body
  collapse collapse-trigger collapse-chevron collapse-panel collapse-text collapse-text-body collapse-more
  palette palette-overlay palette-search palette-input palette-kbd palette-scopes palette-scope palette-list palette-label palette-item palette-avatar palette-sub palette-keys palette-count palette-footer palette-hint palette-spacer
  drawer drawer-overlay drawer-header drawer-heading drawer-title drawer-description drawer-close drawer-body drawer-footer drawer-grab
  modal modal-overlay modal-header modal-heading modal-title modal-description modal-close modal-body modal-footer
  notification-center notification-bell notification-badge notification-float notification-panel notification-header notification-tabs notification-tab notification-read-all notification-group notification-item notification-dot notification-text notification-time notification-avatar notification-body notification-title notification-footer notification-link notification-empty-icon notification-heading notification-spacer notification-tabs-wrap notification-tab-badge notification-unread notification-text-body notification-at notification-empty-title notification-empty-text notification-strong
  popover popover-float popover-card popover-title
  tooltip tooltip-float tooltip-tip
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
  calendar calendar-header calendar-title calendar-views calendar-view calendar-nav calendar-grid calendar-weekday calendar-cell calendar-day calendar-event calendar-more calendar-month calendar-time calendar-hour calendar-legend calendar-swatch calendar-spacer
  due-calendar due-calendar-row due-calendar-date due-calendar-info due-calendar-title due-calendar-subtitle due-calendar-amount due-calendar-status due-calendar-weekday due-calendar-day
  color-picker color-picker-controls color-picker-area color-picker-thumb color-picker-hue color-picker-alpha color-picker-swatches color-picker-swatch
  date-picker date-picker-panel date-picker-presets date-picker-preset date-picker-calendar date-picker-head date-picker-title date-picker-nav date-picker-grid date-picker-letter date-picker-day date-picker-values date-picker-popup
  datetime-picker datetime-picker-panel datetime-picker-times datetime-picker-slot datetime-picker-time-col datetime-picker-zone datetime-picker-split datetime-picker-field datetime-picker-values datetime-picker-popup
  time-picker time-picker-panel time-picker-list time-picker-slot time-picker-popup
  image-input image-input-frame image-input-image image-input-placeholder image-input-initials image-input-overlay image-input-ring image-input-file image-input-reset
  range range-wrap range-head range-label range-track range-fill range-thumb range-step range-steppers range-value range-marks range-mark
  rating rating-star rating-icon rating-half rating-value rating-count rating-distribution rating-summary rating-average rating-total rating-breakdown rating-bar rating-bar-fill
  signature-pad signature-modes signature-mode signature-name signature-surface signature-svg signature-typed signature-base signature-hint signature-footer signature-clear signature-status signature-confirm
  upload-drop-label upload-drop-hint rating-stars rating-grade
  upload upload-drop upload-zone upload-file upload-file-type upload-file-info upload-file-name upload-file-status upload-file-bar upload-file-progress upload-file-done upload-file-retry upload-file-remove upload-thumbs upload-thumb upload-add upload-files upload-button upload-error upload-browse upload-input
  text-editor text-editor-toolbar text-editor-separator text-editor-tool text-editor-wrap text-editor-placeholder text-editor-footer text-editor-actions text-editor-bar text-editor-hint text-editor-ui text-editor-popup text-editor-menu text-editor-content
  summit summit-stars
  avatar avatar-image avatar-status avatar-group avatar-more avatar-more-wrap avatar-more-menu avatar-more-person
  bulk-bar bulk-bar-count bulk-bar-field bulk-bar-separator bulk-bar-action bulk-bar-clear bulk-bar-select-all bulk-bar-spacer bulk-bar-progress bulk-bar-progress-bar bulk-bar-progress-text bulk-bar-confirm-wrap bulk-bar-confirm bulk-bar-confirm-title bulk-bar-confirm-text bulk-bar-confirm-actions bulk-bar-cancel bulk-bar-confirm-button
  card-table card-table-head card-table-title card-table-meta card-table-actions card-table-description card-table-body card-table-foot card-table-sub
  carousel carousel-track carousel-slide carousel-prev carousel-next carousel-fraction carousel-bar carousel-dots carousel-dot carousel-thumbs carousel-thumb
  cash-timer cash-timer-body cash-timer-line cash-timer-clock cash-timer-time cash-timer-amount cash-timer-amount-label cash-timer-amount-value cash-timer-difference cash-timer-stats cash-timer-stat cash-timer-stat-label cash-timer-stat-value
  cover cover-band cover-head cover-avatar cover-text cover-title cover-subtitle cover-image
  description-list description-list-item description-list-term description-list-detail
  mini-card mini-card-text mini-card-label mini-card-title
  pixel-card pixel-card-icon pixel-card-title pixel-card-description pixel-card-arrow pixel-card-grid
  tag tag-swatch tag-remove tag-count tag-group
  timer timer-dot timer-time timer-ring timer-kicker timer-label timer-actions

  checkbox checkbox-input checkbox-text checkbox-description checkbox-group choice choice-input choice-text choice-label choice-description choice-count choice-tick
  radio radio-input radio-text radio-description radio-group
  switch switch-track switch-text switch-description switch-input
  segmented segmented-item segmented-count
  chip chip-count chip-remove person-avatar person-avatar-image
  pill-select
  textarea textarea-control textarea-wrap textarea-mirror textarea-header textarea-footer textarea-counter textarea-counter-row
  otp otp-cell otp-box otp-dash
  number-input number-value number-minus number-plus number-prefix number-suffix
  password-meter password-meter-bar
  input-group addon
  form-section form-section-head form-section-title form-section-description form-section-fields
  select select-control select-value select-chip select-chip-remove select-search select-clear select-native select-panel select-panel-search select-empty select-loading select-footer listbox-option listbox-option-check listbox-option-right listbox-group
  autocomplete autocomplete-control autocomplete-input autocomplete-clear autocomplete-panel autocomplete-empty autocomplete-loading
  tags-input tags-input-control tags-input-tag tags-input-tag-remove tags-input-clear tags-input-counter tags-input-empty tags-input-panel
  phone-input phone-box phone-input-control phone-picker phone-clear phone-search phone-empty phone-panel
  filter-menu filter-popup filter-panel filter-footer filter-group filter-sub filter-section filter-separator filter-count filter-option filter-option-input filter-option-text
  kpi-card kpi-body kpi-inline kpi-text kpi-icon kpi-label kpi-main kpi-value kpi-prefix kpi-number kpi-count kpi-unit kpi-arrow kpi-meter kpi-meter-bar kpi-caption kpi-live kpi-live-dot kpi-footer kpi-delta kpi-compare kpi-open kpi-skeleton
  sparkline sparkline-svg sparkline-area sparkline-line sparkline-dot
  line-chart line-chart-head line-chart-title line-chart-figure line-chart-sub line-chart-delta line-chart-legend line-chart-legend-item line-chart-legend-dash line-chart-legend-swatch line-chart-svg line-chart-gridline line-chart-axis line-chart-x-label line-chart-area line-chart-line line-chart-endpoint line-chart-hover line-chart-guide line-chart-dot line-chart-hit line-chart-tip line-chart-tip-title line-chart-tip-row line-chart-tip-dot line-chart-tip-name line-chart-tip-value
  donut-chart donut-chart-svg donut-chart-segment donut-chart-center donut-chart-center-label donut-chart-center-value donut-chart-row donut-chart-swatch donut-chart-value donut-chart-percent
  waterfall-chart waterfall-chart-svg waterfall-chart-gridline waterfall-chart-axis waterfall-chart-bar waterfall-chart-label waterfall-chart-name waterfall-chart-connector
  bar-chart bar-chart-bar bar-chart-labels bar-chart-label
  cohort-heatmap cohort-heatmap-head cohort-heatmap-corner cohort-heatmap-column cohort-heatmap-body cohort-heatmap-row cohort-heatmap-label cohort-heatmap-cell cohort-heatmap-value
  bar-list bar-list-item bar-list-row bar-list-label bar-list-value bar-list-track bar-list-bar
  heatmap heatmap-grid heatmap-cell heatmap-scale heatmap-less heatmap-more heatmap-swatch
  chart
  # Shell/app B: app_shell, shell, sidebar, navbar, landing_nav, logo, auth_split, container, scroll_area, sticky, theme_picker, theme_switch
  app-shell app-shell-main app-shell-preloader auth-alert auth-art-box auth-brand auth-chip auth-glass auth-page auth-sent auth-split auth-submit brand container
  container-span framed-sidebar header header-notifications header-search header-search-results horizontal-nav-box horizontal-nav-divider horizontal-nav-menu
  landing-announcement landing-brand landing-feature landing-mega landing-mega-side landing-nav landing-nav-ham landing-nav-mobile landing-product logo logo-mark
  logo-word main-sidebar main-sidebar-link main-sidebar-logo monochrome-toggle monochrome-toggle-track navbar navbar-avatars navbar-bell navbar-brand navbar-chip
  navbar-crumbs navbar-env navbar-icon navbar-lang navbar-links navbar-menu-head navbar-menu-row navbar-menu-status navbar-search navbar-sep navbar-slash navbar-sync
  navbar-tabs navbar-title navbar-user navbar-workspace nav-caret oauth-button page-header page-header-crumbs plan rail-heading rail-link rail-logo rail-module rail-panel
  rail-user rail-workspace right-sidebar right-sidebar-scrim scroll-area scroll-area-bar scroll-area-bar-x shell shell-main shell-wire-side sidebar sidebar-drawer
  sidebar-min-divider sidebar-min-group sidebar-min-link sidebar-nav sidebar-nav-divider sidebar-nav-group sidebar-nav-link sidebar-panel sidebar-panel-min
  sidebar-profile sidebar-profile-box sidebar-toggle sideblock sticky sticky-body sticky-header sub-nav tab-bar tab-bar-slot team theme-box theme-picker
  theme-picker-button theme-picker-option theme-picker-pop theme-switch theme-switch-item theme-switch-track theme-toggle trial user version
  app-shell-span auth-alert-span auth-art-b auth-art-div auth-art-q auth-art-small auth-art-span auth-page-div auth-page-div-2 auth-page-div-3 auth-page-dynamic_tag
  auth-page-span auth-sent-div auth-sent-span auth-split-blockquote auth-split-div auth-split-div-2 auth-split-div-3 auth-split-div-4 auth-split-div-5 auth-split-div-6
  auth-split-div-7 auth-split-div-8 auth-split-div-9 auth-split-figcaption auth-split-figure auth-split-hr auth-split-hr-2 auth-split-img auth-split-span
  auth-split-span-2 auth-split-span-3 auth-submit-span chart-mark-svg framed-sidebar-b framed-sidebar-button framed-sidebar-button-2 framed-sidebar-div
  framed-sidebar-div-2 framed-sidebar-div-3 framed-sidebar-div-4 framed-sidebar-nav framed-sidebar-span framed-sidebar-span-2 grid-div grid-div-2 grid-i grid-i-2 grid-i-3
  grid-span grow-div header-div header-div-2 header-img header-link header-nav header-tools-button header-tools-div header-tools-div-2 header-tools-input
  horizontal-nav-link-link horizontal-nav-menu-button horizontal-nav-menu-link landing-announcement-button landing-announcement-link landing-announcement-span
  landing-feature-span landing-feature-span-2 landing-feature-span-3 landing-login-link landing-logo-img landing-logo-span landing-mega-div landing-mega-side-link
  landing-mega-side-span landing-mega-side-span-2 landing-mega-side-span-3 landing-nav-a landing-nav-button landing-nav-div landing-nav-div-2 landing-nav-link
  landing-nav-link-2 landing-nav-span landing-product-b landing-product-div landing-product-div-2 landing-product-span landing-product-span-2 landing-product-span-3
  main-sidebar-div main-sidebar-div-2 main-sidebar-img main-sidebar-img-2 menu-span monochrome-toggle-span navbar-bell-b navbar-brand-img navbar-brand-span
  navbar-chip-span navbar-crumbs-link navbar-crumbs-span navbar-crumbs-span-2 navbar-div navbar-div-2 navbar-env-span navbar-lang-button navbar-lang-link
  navbar-links-link navbar-menu-head-b navbar-menu-head-span navbar-menu-head-span-2 navbar-menu-head-span-3 navbar-menu-item-button navbar-menu-item-link
  navbar-menu-item-span navbar-menu-item-span-2 navbar-menu-row-span navbar-menu-status-span navbar-menu-status-span-2 navbar-search-input navbar-search-span
  navbar-tabs-link navbar-tabs-span navbar-user-button navbar-user-div navbar-workspace-b navbar-workspace-button navbar-workspace-img navbar-workspace-span
  navbar-workspace-span-2 navbar-workspace-span-3 page-header-button page-header-crumbs-link page-header-crumbs-span page-header-crumbs-span-2 page-header-div
  page-header-div-2 page-header-div-3 page-header-div-4 page-header-div-5 page-header-div-6 page-header-div-7 page-header-link page-header-p page-header-p-2
  page-header-p-3 page-header-p-4 page-header-span page-header-span-2 page-header-span-3 plan-action-span plan-action-span-2 rail-btn-link rail-btn-span rail-btn-span-2
  rail-extra-btn-link rail-link-span rail-link-span-2 rail-module-button rail-module-div rail-module-div-2 rail-module-link rail-module-span rail-module-span-2
  rail-toggle-button rail-user-b rail-user-span rail-user-span-2 rail-user-span-3 rail-workspace-b rail-workspace-span rail-workspace-span-2 rail-workspace-span-3
  render-logo-svg render-logo-svg-2 right-sidebar-aside right-sidebar-button right-sidebar-div right-sidebar-div-2 right-sidebar-div-3 right-sidebar-div-4
  right-sidebar-toggle-button shell-div shell-div-2 shell-div-3 shell-i shell-i-2 shell-i-3 shell-i-4 sidebar-brand-b sidebar-brand-img sidebar-brand-span
  sidebar-brand-span-2 sidebar-brand-span-3 sidebar-button sidebar-entries-div sidebar-entries-div-2 sidebar-group-div sidebar-group-div-2 sidebar-item-div
  sidebar-item-inner-span sidebar-item-inner-span-2 sidebar-item-inner-span-3 sidebar-item-inner-span-4 sidebar-item-link sidebar-item-link-2 sidebar-item-link-3
  sidebar-item-span sidebar-item-span-2 sidebar-menu-button sidebar-menu-div sidebar-menu-div-2 sidebar-menu-link sidebar-menu-span sidebar-menu-span-2
  sidebar-nav-group-button sidebar-nav-group-div sidebar-nav-group-link sidebar-panel-min-div sidebar-plan-div sidebar-plan-span sidebar-plan-span-2 sidebar-plan-span-3
  sidebar-plan-span-4 sidebar-profile-b sidebar-profile-button sidebar-profile-div sidebar-profile-div-2 sidebar-profile-div-3 sidebar-profile-link sidebar-profile-small
  sidebar-profile-span sidebar-profile-span-2 sidebar-profile-span-3 sidebar-profile-span-4 sidebar-rail-button sidebar-rail-div sidebar-rail-img sidebar-rail-nav
  sidebar-sections-div sidebar-team-b sidebar-team-div sidebar-team-div-2 sidebar-team-img sidebar-team-span sidebar-team-span-2 sidebar-team-span-3 sidebar-tree-button
  sidebar-tree-div sidebar-tree-div-2 sidebar-trial-span sidebar-trial-span-2 sidebar-trial-span-3 sidebar-trial-span-4 sidebar-user-b sidebar-user-menu-b
  sidebar-user-menu-b-2 sidebar-user-menu-div sidebar-user-menu-div-2 sidebar-user-menu-div-3 sidebar-user-menu-div-4 sidebar-user-menu-div-5 sidebar-user-menu-span
  sidebar-user-menu-span-2 sidebar-user-menu-span-3 sidebar-user-menu-span-4 sidebar-user-menu-span-5 sidebar-user-span sidebar-user-span-2 sidebar-user-span-3
  sidebar-version-link sidebar-version-span sidebar-version-span-2 sidebar-version-span-3 sideblock-img sideblock-link sideblock-span sub-nav-button tab-bar-link
  theme-switch-span theme-toggle-span theme-toggle-span-2 wi-i wire-bar-div wire-bar-div-2 wire-main-b wire-main-b-2 wire-main-b-3 wire-main-div wire-main-div-2 word-span
  word-span-2
  navbar-search-placeholder
  page-header-h1 page-header-h1-2 sidebar-panel-h4 sidebar-rail-h4 sub-nav-h4
  nav-r
  scroll-area-content
)
