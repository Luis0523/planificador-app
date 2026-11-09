import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/clima_service.dart';
import 'clima_indicator.dart';

class ClimaDiaChart extends StatelessWidget {
  const ClimaDiaChart({super.key, required this.puntos});

  final List<ClimaInfo> puntos;

  @override
  Widget build(BuildContext context) {
    if (puntos.isEmpty) return const SizedBox.shrink();

    final minimo = puntos
        .map((p) => p.temperaturaC)
        .reduce((a, b) => a < b ? a : b);
    final maximo = puntos
        .map((p) => p.temperaturaC)
        .reduce((a, b) => a > b ? a : b);
    final minY = (minimo - 2).floorToDouble();
    final maxY = (maximo + 2).ceilToDouble();
    final intervalo = ((maxY - minY) / 4).ceilToDouble().clamp(1.0, 20.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Temperatura (°C)',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: PlanazoColors.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '${minimo.round()}° – ${maximo.round()}°',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: PlanazoColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: puntos.length <= 1 ? 1 : (puntos.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: intervalo,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: PlanazoColors.outlineVariant,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: intervalo,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.round()}°',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 1,
                    getTitlesWidget: _horaYCondicion,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < puntos.length; i++)
                      FlSpot(i.toDouble(), puntos[i].temperaturaC),
                  ],
                  isCurved: true,
                  color: PlanazoColors.secondary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final color = ClimaIndicator.datosVisuales(
                        puntos[index].condicion,
                      ).$2;
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: color,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: PlanazoColors.secondary.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _horaYCondicion(double value, TitleMeta meta) {
    final indice = value.round();
    if (indice < 0 || indice >= puntos.length) {
      return const SizedBox.shrink();
    }

    final punto = puntos[indice];
    final (icono, color) = ClimaIndicator.datosVisuales(punto.condicion);
    final hora = punto.fecha.hour.toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color),
        Text('${hora}h', style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}
