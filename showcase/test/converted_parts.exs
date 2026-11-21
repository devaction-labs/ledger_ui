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
  ai-chat ai-chat-footer ai-chat-footnote ai-chat-header ai-chat-messages ai-chat-scroll ai-composer ai-composer-actions ai-composer-attach ai-composer-chip ai-composer-file ai-composer-file-size ai-composer-files ai-composer-input ai-composer-send ai-composer-typed ai-composer-typing ai-greeting ai-greeting-line ai-greeting-tagline ai-insight ai-insight-action ai-insight-body ai-insight-footer ai-insight-text ai-insight-title ai-insights ai-insights-actions ai-insights-body ai-insights-header ai-insights-title ai-message ai-message-actions ai-message-avatar ai-message-body ai-message-bubble ai-message-content ai-message-dot ai-message-error ai-message-spark ai-message-typing ai-promo ai-promo-action ai-promo-call ai-promo-icon ai-promo-lead ai-promo-row ai-promo-sub ai-promo-text ai-promo-titles ai-proposal ai-proposal-body ai-proposal-change ai-proposal-changes ai-proposal-content ai-proposal-footer ai-proposal-from ai-proposal-grid ai-proposal-head ai-proposal-header ai-proposal-impact ai-proposal-label ai-proposal-note ai-proposal-pending-note ai-proposal-preview ai-proposal-preview-box ai-proposal-row ai-proposal-spacer ai-proposal-table ai-proposal-td ai-proposal-th ai-proposal-title ai-proposal-to ai-tool-trace ai-tool-trace-detail ai-tool-trace-ms ai-tool-trace-name ai-tool-trace-ok ai-tool-trace-row ai-tool-trace-run ai-tool-trace-spacer ai-tool-trace-status ai-tool-trace-summary ai-tool-trace-title ai-tool-trace-total conversation-heading conversation-item conversation-list conversation-list-search conversation-list-tools conversation-pending conversation-status conversation-title prompt-suggestion prompt-suggestion-text prompt-suggestion-title prompt-suggestions
  code-block code-block-actions code-block-copy code-block-copy-label code-block-footer code-block-header code-block-pre code-line code-line-number code-token
  email-preview email-preview-brand email-preview-card email-preview-footer email-preview-line email-preview-logo email-preview-title
  glow-text
  tool tool-approval tool-approval-actions tool-approval-description tool-approval-head tool-approval-text tool-approval-title tool-description tool-ring tool-text tool-title
  trace trace-bar trace-bar-fill trace-description trace-duration trace-line trace-spinner trace-step trace-step-body trace-step-summary trace-title
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

  kanban kanban-column kanban-column-header kanban-column-count kanban-column-meta kanban-column-progress kanban-column-empty kanban-column-hint kanban-card kanban-lost
  timeline timeline-item timeline-point timeline-text timeline-event timeline-icon timeline-day
  step-group step-group-header step-group-mark step-group-step step-group-panel step-group-log step-group-line
  treeview tree-item tree-chevron tree-spacer tree-check tree-check-input tree-count tree-children
  hero-card hero-text hero-eyebrow hero-extra hero-meta hero-meter hero-steps hero-actions hero-art
  flow flow-node flow-node-status flow-hint flow-toolbar flow-panel flow-section flow-chips flow-panel-head flow-panel-tabs flow-panel-body flow-panel-foot flow-handle flow-menu flow-menu-item flow-edge-label
  table table-wrap table-head-cell table-cell table-row table-panel-row table-panel table-panel-item table-detail-row table-empty table-copy table-copy-value table-copy-tip table-checkbox table-checkbox-input
  data-table data-table-toolbar data-table-header data-table-title data-table-filters data-table-body data-table-footer data-table-pager data-table-page table-search table-toolbar table-filter-chip table-clear
  data-table-actions data-table-size data-table-size-select data-table-spacer flow-board flow-hint-title flow-menu-label flow-menu-sub flow-node-actions flow-node-body flow-node-head flow-node-kind flow-node-metrics flow-node-sub flow-node-text flow-node-title flow-panel-title flow-scroll flow-section-label flow-stage hero-description hero-meta-row hero-meta-value hero-meter-bar hero-step kanban-card-actions kanban-card-grip kanban-column-bar kanban-column-empty-icon kanban-column-empty-text kanban-column-empty-title kanban-column-spacer kanban-column-total kanban-lost-count kanban-lost-icon kanban-lost-label step-group-duration step-group-line-n step-group-result step-group-title table-body table-copy-done table-copy-idle table-copy-text table-detail table-filter-remove table-foot-row table-head table-head-row table-panel-key table-panel-value table-search-input table-skeleton table-skeleton-avatar table-toolbar-label table-toolbar-row table-toolbar-spacer timeline-description timeline-subtitle timeline-time timeline-title
  hero-title step-group-time
  # Shell/app B: app_shell, shell, sidebar, navbar, landing_nav, logo, auth_split, container, scroll_area, sticky, theme_picker, theme_switch
  app-shell app-shell-main app-shell-preloader auth-alert auth-art-box auth-brand auth-chip auth-glass auth-page auth-sent auth-split auth-submit brand container
  framed-sidebar header header-notifications header-search header-search-results horizontal-nav-box horizontal-nav-divider horizontal-nav-menu
  landing-announcement landing-brand landing-feature landing-mega landing-mega-side landing-nav landing-nav-ham landing-nav-mobile landing-product logo logo-mark
  logo-word main-sidebar main-sidebar-link main-sidebar-logo monochrome-toggle monochrome-toggle-track navbar navbar-avatars navbar-bell navbar-brand navbar-chip
  navbar-crumbs navbar-env navbar-icon navbar-lang navbar-links navbar-menu-head navbar-menu-row navbar-menu-status navbar-search navbar-sep navbar-slash navbar-sync
  navbar-tabs navbar-title navbar-user navbar-workspace nav-caret oauth-button page-header page-header-crumbs plan rail-heading rail-link rail-logo rail-module rail-panel
  rail-user rail-workspace right-sidebar right-sidebar-scrim scroll-area scroll-area-bar scroll-area-bar-x shell shell-main shell-wire-side sidebar sidebar-drawer
  sidebar-min-divider sidebar-min-group sidebar-min-link sidebar-nav sidebar-nav-divider sidebar-nav-group sidebar-nav-link sidebar-panel sidebar-panel-min
  sidebar-profile sidebar-profile-box sidebar-toggle sideblock sticky sticky-body sticky-header sub-nav tab-bar tab-bar-slot team theme-box theme-picker
  theme-picker-button theme-picker-option theme-picker-pop theme-switch theme-switch-item theme-switch-track theme-toggle trial user version
  auth-art-q auth-page-dynamic_tag
  auth-split-blockquote
  auth-split-figcaption auth-split-figure auth-split-img
  framed-sidebar-button
  framed-sidebar-nav
  header-img header-link header-nav header-tools-button header-tools-input
  horizontal-nav-link-link horizontal-nav-menu-button horizontal-nav-menu-link landing-announcement-button landing-announcement-link
  landing-login-link landing-logo-img landing-mega-side-link
  landing-nav-button landing-nav-link
  main-sidebar-img navbar-brand-img
  navbar-crumbs-link navbar-lang-button navbar-lang-link
  navbar-links-link navbar-menu-item-button navbar-menu-item-link
  navbar-search-input
  navbar-tabs-link navbar-user-button navbar-workspace-button navbar-workspace-img
  page-header-button page-header-crumbs-link
  page-header-link
  rail-btn-link
  rail-extra-btn-link rail-module-button rail-module-link
  rail-toggle-button
  right-sidebar-button
  right-sidebar-toggle-button sidebar-brand-img
  sidebar-button
  sidebar-item-link
  sidebar-menu-button sidebar-menu-link
  sidebar-nav-group-button sidebar-nav-group-link
  sidebar-profile-button sidebar-profile-link
  sidebar-rail-button sidebar-rail-img sidebar-rail-nav
  sidebar-team-img sidebar-tree-button
  sidebar-version-link sideblock-img sideblock-link sub-nav-button tab-bar-link
  navbar-search-placeholder
  nav-r
  scroll-area-content
  logo-word-stack logo-context logo-mark-glyph logo-glyph container-preview-label theme-switch-label theme-toggle-moon theme-toggle-sun theme-picker-swatch
  theme-picker-swatch-accent theme-picker-swatch-ink theme-picker-swatch-accent-faint theme-picker-caption theme-picker-check theme-picker-menu-check
  shell-wire-rail shell-wire-rail-dot shell-wire-rail-dot-active shell-wire-column shell-wire-rail-column wire-item wire-bar wire-bar-simple wire-main
  wire-main-cards wire-main-card landing-nav-spacer landing-nav-panel landing-nav-panel-link landing-nav-panel-actions landing-logo-mark landing-mega-side-slot
  landing-product-head landing-product-logo landing-product-title landing-product-link landing-product-preview landing-product-mock landing-feature-icon
  landing-feature-text landing-feature-description landing-mega-side-eyebrow landing-mega-side-text landing-mega-side-thumb landing-announcement-eyebrow
  auth-split-form-side auth-split-form auth-split-title auth-split-subtitle auth-split-divider auth-split-divider-label auth-split-footer auth-split-aside
  auth-split-art-side auth-split-art auth-split-rating auth-split-quote-role auth-page-header auth-page-brand auth-page-mark auth-page-footer auth-art-author
  auth-art-author-text auth-art-author-name auth-art-author-role auth-sent-icon auth-sent-text auth-alert-text auth-submit-spinner navbar-row navbar-tabs-row
  navbar-brand-mark navbar-crumbs-separator navbar-crumbs-current navbar-workspace-logo navbar-workspace-text navbar-workspace-name navbar-workspace-sub
  navbar-chip-square navbar-tabs-count navbar-search-value navbar-bell-count navbar-env-dot navbar-user-menu navbar-menu-head-text navbar-menu-head-name
  navbar-menu-head-email navbar-menu-head-badge navbar-menu-status-dot navbar-menu-status-action navbar-menu-row-end navbar-menu-item-end sidebar-spacer
  sidebar-sections-footer sidebar-tree-head sidebar-tree-brand sidebar-rail-title sidebar-rail-try-heading sidebar-brand-logo sidebar-brand-text
  sidebar-brand-name sidebar-brand-sub sidebar-chart-mark sidebar-team-wrap sidebar-team-logo sidebar-team-text sidebar-team-name sidebar-team-plan
  sidebar-team-popover sidebar-user-menu-wrap sidebar-user-menu-trigger sidebar-user-menu-person sidebar-user-menu-text sidebar-user-menu-name
  sidebar-user-menu-sub sidebar-user-menu-popover sidebar-user-menu-head sidebar-user-menu-head-text sidebar-user-menu-head-name sidebar-user-menu-head-sub
  sidebar-user-menu-separator sidebar-menu-separator sidebar-menu-heading sidebar-menu-item-end sidebar-entries-run sidebar-entries-separator
  sidebar-group-heading sidebar-group-items sidebar-item-disabled sidebar-item-child-link sidebar-item-children sidebar-item-dotted-link sidebar-item-dot
  sidebar-item-chip sidebar-item-count sidebar-item-kbd sidebar-item-badge rail-btn-count rail-btn-dot sidebar-user-person sidebar-user-text sidebar-user-name
  sidebar-user-sub sidebar-plan-head sidebar-plan-icon sidebar-plan-text sidebar-plan-detail sidebar-plan-description plan-action-avatars plan-action-icon
  sidebar-trial-label sidebar-trial-text sidebar-trial-progress sidebar-trial-bar sidebar-version-dot sidebar-version-text sidebar-version-build
  app-shell-preloader-spinner main-sidebar-logo-image main-sidebar-spacer sidebar-profile-head sidebar-profile-text sidebar-profile-name sidebar-profile-sub
  sidebar-profile-separator sidebar-profile-item-icon sidebar-profile-item-text sidebar-profile-item-description sidebar-profile-footer sidebar-panel-title
  sidebar-nav-group-items sidebar-panel-min-spacer sideblock-logo header-spacer header-search-wrap header-notifications-wrap right-sidebar-panel
  right-sidebar-head right-sidebar-title right-sidebar-body right-sidebar-footer framed-sidebar-brand framed-sidebar-logo framed-sidebar-wordmark
  framed-sidebar-wordmark-name framed-sidebar-workspace framed-sidebar-search framed-sidebar-spacer framed-sidebar-bottom rail-link-label rail-link-badge
  rail-module-label rail-module-badge rail-module-body rail-module-items rail-workspace-logo rail-workspace-text rail-workspace-name rail-workspace-sub
  rail-user-person rail-user-text rail-user-name rail-user-sub page-header-title page-header-description page-header-subtitle page-header-actions
  page-header-tabs page-header-top page-header-spacer page-header-clock page-header-row page-header-heading page-header-badge page-header-crumbs-separator
  page-header-crumbs-current monochrome-toggle-label sub-nav-title auth-split-divider-line
)
