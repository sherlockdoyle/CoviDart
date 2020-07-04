import 'package:flutter/material.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'covidAPI.dart';

void main() => runApp(CovidApp());

class CovidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('CoviDart'),
        ),
        body: Column(
          children: [
            Container(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Just a sample COVID-19 tracker Flutter app. Find the code at '),
                    TextSpan(
                      text: 'https://github.com/sherlockdoyle/covidart',
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        decoration: TextDecoration.underline,
                      ),
                      // recognizer: TapGestureRecognizer()  // TODO: Why no work?
                      //   ..onTap = () async {
                      //     print('Kojufrsre');
                      //     const loc = 'https://github.com/sherlockdoyle/covidart';
                      //     if (await url.canLaunch(loc)) url.launch(loc);
                      //   },
                    ),
                    TextSpan(text: '.'),
                  ],
                  style: TextStyle(color: Colors.white),
                ),
              ),
              // child: Text('Just a sample COVID-19 tracker Flutter app.'),
              padding: EdgeInsets.all(10),
            ),
            Expanded(child: Center(child: DataWidget())),
          ],
        ),
      ),
    );
  }
}

class DataWidget extends StatefulWidget {
  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  Future<List<Country>> countries;
  Country selected;
  Future<CountryCase> data;

  @override
  void initState() {
    super.initState();
    countries = CovidAPI.getCountries()
      ..then((value) {
        final localCountryCode = Localizations.localeOf(context).countryCode;
        final localCountryIdx = value.indexWhere((element) => element.iso2 == localCountryCode);
        if (localCountryIdx >= 0) {
          selected = value[localCountryIdx];
          updateCountryData();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<List<Country>>(
          future: countries,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SearchableDropdown<Country>(
                items: snapshot.data
                    .map((e) => DropdownMenuItem<Country>(
                          value: e,
                          child: Text(e.toString()),
                        ))
                    .toList(),
                onChanged: (e) {
                  selected = e;
                  updateCountryData();
                },
                hint: 'Select country',
                searchHint: 'Search for country',
                value: selected,
              );
            } else if (snapshot.hasError) return Text('${snapshot.error}', style: TextStyle(color: Colors.red));
            return CircularProgressIndicator();
          },
        ),
        SizedBox(
          height: 10,
        ),
        FutureBuilder<CountryCase>(
          future: data,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                height: 400,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: charts.TimeSeriesChart(
                  <charts.Series<Case, DateTime>>[
                    charts.Series(
                      id: 'Confirmed',
                      data: snapshot.data.cases,
                      domainFn: (datum, index) => datum.date,
                      measureFn: (datum, index) => datum.confirmed,
                      colorFn: (datum, index) => charts.MaterialPalette.blue.shadeDefault,
                    ),
                    charts.Series(
                      id: 'Deaths',
                      data: snapshot.data.cases,
                      domainFn: (datum, index) => datum.date,
                      measureFn: (datum, index) => datum.deaths,
                      colorFn: (datum, index) => charts.MaterialPalette.red.shadeDefault,
                    ),
                    charts.Series(
                      id: 'Recovered',
                      data: snapshot.data.cases,
                      domainFn: (datum, index) => datum.date,
                      measureFn: (datum, index) => datum.recovered,
                      colorFn: (datum, index) => charts.MaterialPalette.green.shadeDefault,
                    ),
                    charts.Series(
                      id: 'Active',
                      data: snapshot.data.cases,
                      domainFn: (datum, index) => datum.date,
                      measureFn: (datum, index) => datum.active,
                      colorFn: (datum, index) => charts.MaterialPalette.yellow.shadeDefault,
                    ),
                  ],
                  behaviors: [charts.SeriesLegend()],
                  animate: true,
                  primaryMeasureAxis: charts.NumericAxisSpec(
                    renderSpec: charts.GridlineRendererSpec(
                      labelStyle: charts.TextStyleSpec(
                        color: charts.MaterialPalette.white,
                      ),
                      axisLineStyle: charts.LineStyleSpec(
                        color: charts.MaterialPalette.gray.shadeDefault,
                      ),
                    ),
                  ),
                  domainAxis: charts.DateTimeAxisSpec(
                    renderSpec: charts.GridlineRendererSpec(
                      labelStyle: charts.TextStyleSpec(
                        color: charts.MaterialPalette.white,
                      ),
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) return Text('${snapshot.error}', style: TextStyle(color: Colors.red));
            return CircularProgressIndicator();
          },
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }

  void updateCountryData() => data = CovidAPI.getCasesByCountry(selected)..then((value) => setState(() {}));
}
