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
        body: Center(
          child: DataWidget(),
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
                child: Card(
                  child: charts.TimeSeriesChart(
                    <charts.Series<Case, DateTime>>[
                      charts.Series(
                        id: snapshot.data.country.toString(),
                        data: snapshot.data.cases,
                        domainFn: (datum, index) => datum.date,
                        measureFn: (datum, index) => datum.confirmed,
                        colorFn: (datum, index) => charts.ColorUtil.fromDartColor(Colors.orange),
                      ),
                      charts.Series(
                        id: snapshot.data.country.toString(),
                        data: snapshot.data.cases,
                        domainFn: (datum, index) => datum.date,
                        measureFn: (datum, index) => datum.deaths,
                        colorFn: (datum, index) => charts.ColorUtil.fromDartColor(Colors.red),
                      ),
                      charts.Series(
                        id: snapshot.data.country.toString(),
                        data: snapshot.data.cases,
                        domainFn: (datum, index) => datum.date,
                        measureFn: (datum, index) => datum.recovered,
                        colorFn: (datum, index) => charts.ColorUtil.fromDartColor(Colors.green),
                      ),
                      charts.Series(
                        id: snapshot.data.country.toString(),
                        data: snapshot.data.cases,
                        domainFn: (datum, index) => datum.date,
                        measureFn: (datum, index) => datum.active,
                        colorFn: (datum, index) => charts.ColorUtil.fromDartColor(Colors.blue),
                      ),
                    ],
                    animate: true,
                    dateTimeFactory: charts.LocalDateTimeFactory(),
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

  void updateCountryData() => setState(() {
        data = CovidAPI.getCasesByCountry(selected);
      });
}
