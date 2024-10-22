import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DiseaseDetectionPage extends StatelessWidget {
  const DiseaseDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffB81736), Color(0xff281537)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Heart Disease Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Disease Detected: Heart Disease',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffB81736),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildRiskFactorChart(),
                      const SizedBox(height: 30),
                      _buildHeartRateChart(),
                      const SizedBox(height: 30),
                      _buildCholesterolLevels(),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to doctor-finding page
                        },
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text('Find Specialists',style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff281537),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskFactorChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk Factors',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const titles = ['Age', 'BMI', 'BP', 'Smoking'];
                      return Text(
                        titles[value.toInt()],
                        style: const TextStyle(color: Color(0xff281537), fontSize: 12),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 75, color: const Color(0xffB81736))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 56, color: const Color(0xffB81736))]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 82, color: const Color(0xffB81736))]),
                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 45, color: const Color(0xffB81736))]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeartRateChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heart Rate Variability',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Color(0xff281537), fontSize: 12),
                      );
                    },
                    interval: 2,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 3),
                    const FlSpot(2, 2),
                    const FlSpot(4, 5),
                    const FlSpot(6, 3.1),
                    const FlSpot(8, 4),
                    const FlSpot(10, 3),
                  ],
                  isCurved: true,
                  color: const Color(0xffB81736),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: const Color(0xffB81736).withOpacity(0.2)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCholesterolLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cholesterol Levels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: const Color(0xffB81736),
                  value: 40,
                  title: 'LDL',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: const Color(0xff281537),
                  value: 30,
                  title: 'HDL',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: 15,
                  title: 'VLDL',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: 15,
                  title: 'TG',
                  radius: 50,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}