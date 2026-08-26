import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_keys.dart';
import '../cubit/reader_settings_cubit.dart';

/// Panel inferior para ajustar la comodidad visual del lector.
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  /// Construye controles táctiles para tamaño e interlineado de lectura.
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderSettingsCubit, ReaderSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReaderSettingsCubit>();

        return SafeArea(
          child: Padding(
            key: AppKeys.readerSettingsSheet,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ajustes de lectura',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ReaderSlider(
                  key: AppKeys.readerFontScaleSlider,
                  title: 'Tamaño del texto',
                  value: state.fontScale,
                  min: ReaderSettingsCubit.minFontScale,
                  max: ReaderSettingsCubit.maxFontScale,
                  divisions: 10,
                  label: _percentLabel(state.fontScale),
                  onChanged: cubit.setFontScale,
                ),
                _ReaderSlider(
                  key: AppKeys.readerLineHeightSlider,
                  title: 'Espaciado entre líneas',
                  value: state.lineHeight,
                  min: ReaderSettingsCubit.minLineHeight,
                  max: ReaderSettingsCubit.maxLineHeight,
                  divisions: 11,
                  label: state.lineHeight.toStringAsFixed(2),
                  onChanged: cubit.setLineHeight,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: AppKeys.readerSettingsReset,
                    onPressed: cubit.reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restablecer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Convierte la escala decimal en porcentaje legible para el usuario.
  String _percentLabel(double value) {
    return '${(value * 100).round()}%';
  }
}

/// Control compacto reutilizable para preferencias numéricas del lector.
class _ReaderSlider extends StatelessWidget {
  const _ReaderSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    super.key,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  /// Renderiza etiqueta, valor y slider sin cambiar la altura del panel.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
