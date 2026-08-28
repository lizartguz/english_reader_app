import 'package:flutter/material.dart';

import '../layout/responsive_breakpoints.dart';

/// Opción seleccionable de un filtro rápido por categoría.
class AppFilterOption {
  const AppFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Barra compartida de búsqueda y filtros para listados de la aplicación.
class AppListFilterBar extends StatelessWidget {
  const AppListFilterBar({
    required this.controller,
    required this.searchLabel,
    required this.onQueryChanged,
    this.searchFieldKey,
    this.options = const <AppFilterOption>[],
    this.selectedOption,
    this.onOptionSelected,
    this.resultsLabel,
    super.key,
  });

  final Key? searchFieldKey;
  final TextEditingController controller;
  final String searchLabel;
  final ValueChanged<String> onQueryChanged;
  final List<AppFilterOption> options;
  final String? selectedOption;
  final ValueChanged<String?>? onOptionSelected;
  final String? resultsLabel;

  /// Renderiza búsqueda, chips y conteo con el ancho de lectura del listado.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: ResponsiveBreakpoints.pagePadding(
            constraints.maxWidth,
          ).copyWith(bottom: 0),
          child: ResponsiveContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: searchFieldKey,
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: searchLabel,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              controller.clear();
                              onQueryChanged('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: onQueryChanged,
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FilterChips(
                    options: options,
                    selectedOption: selectedOption,
                    onOptionSelected: onOptionSelected,
                  ),
                ],
                if (resultsLabel != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      resultsLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fila de chips que alterna entre ver todo y una categoría concreta.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  final List<AppFilterOption> options;
  final String? selectedOption;
  final ValueChanged<String?>? onOptionSelected;

  /// Envuelve los chips en varias líneas para no ocultarlos en móvil.
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          label: 'Todas',
          selected: selectedOption == null,
          onSelected: () => onOptionSelected?.call(null),
        ),
        for (final option in options)
          _chip(
            label: option.label,
            selected: selectedOption == option.value,
            onSelected: () => onOptionSelected?.call(
              selectedOption == option.value ? null : option.value,
            ),
          ),
      ],
    );
  }

  /// Aplica la misma apariencia y ayuda contextual a cada chip del filtro.
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      tooltip: 'Filtrar por $label',
    );
  }
}
