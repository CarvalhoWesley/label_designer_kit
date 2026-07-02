import 'package:label_core/label_core.dart';
import 'package:mobx/mobx.dart';

part 'document_store.g.dart';

/// Source of truth for the [LabelDocument] currently being edited.
///
/// Every mutation flows through [HistoryStore], which is the only store
/// allowed to call [replaceDocument] — that's what makes every edit
/// undo-able by construction (see `docs/ARCHITECTURE.md` section 15).
class DocumentStore = DocumentStoreBase with _$DocumentStore;

abstract class DocumentStoreBase with Store {
  DocumentStoreBase(LabelDocument initialDocument) : document = initialDocument;

  @observable
  LabelDocument document;

  @computed
  List<LabelElement> get elements => document.elements;

  @computed
  List<LabelLayer> get layers => document.layers;

  @computed
  List<LabelStyle> get styles => document.styles;

  @computed
  List<LabelVariable> get variables => document.variables;

  /// Replaces the current document wholesale. Called by [HistoryStore]
  /// after executing/undoing/redoing a command, or when loading a
  /// different document entirely.
  @action
  void replaceDocument(LabelDocument newDocument) {
    document = newDocument;
  }
}
