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
)
