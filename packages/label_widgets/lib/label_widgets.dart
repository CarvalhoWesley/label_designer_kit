/// Reusable UI kit for the editor: buttons, color picker, rulers and a
/// semantic icon set. See `docs/ARCHITECTURE.md` section 7.
///
/// Purely presentational — nothing here imports `label_core` or
/// `label_designer_state`. Widgets take plain values and callbacks; owning
/// state (a `LabelDocument`, a store) is always the caller's job.
library;

export 'src/buttons/label_button.dart';
export 'src/buttons/label_toolbar_button.dart';
export 'src/color/hex_color.dart';
export 'src/color/label_color_picker.dart';
export 'src/color/label_color_swatch.dart';
export 'src/icons/label_icons.dart';
export 'src/panels/resizable_panel.dart';
export 'src/ruler/label_ruler.dart';
export 'src/ruler/ruler_ticks.dart';
