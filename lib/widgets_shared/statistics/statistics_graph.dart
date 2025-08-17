import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';

Widget statisticsGraph(ChartData chartData, double width, BuildContext context, Function updateWidth) {
  return Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleUpdate: (details) {
            updateWidth((width * details.scale).clamp(MediaQuery.of(context).size.width * 0.8, 2000.0));
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: 
            SizedBox(
              width: width + 32.0,
              child: (chartData.dataRowsLegends.isNotEmpty) ? LineChart(
                size: Size.fromWidth(width),
                painter: LineChartPainter(
                  lineChartContainer: LineChartTopContainer(
                    chartData: chartData
                  ),
                ),
              )
              :
              const SizedBox.shrink()
            ),
          )
        )
      ),
    ),
  );
}