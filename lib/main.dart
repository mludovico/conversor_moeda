import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(
      primaryColor: Colors.white,
      hintColor: Colors.amber
    ),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final realController = TextEditingController();
  final dolarController = TextEditingController();
  final euroController = TextEditingController();
  final dataController = TextEditingController();

  void clearAll(){
    dataController.text = "";
    realController.text = "";
    dolarController.text = "";
    euroController.text = "";
  }

  void _realChanged(String text)async{
    if(text.isEmpty){
      clearAll();
      return;
    }
    var valorDolar = double.parse(text) / Dolar;
    var valorEuro = double.parse(text) / Euro;
    print("Real: $text");
    print("Dolar: $valorDolar");
    print("Euro: $valorEuro");
    dolarController.text = valorDolar.toStringAsFixed(2);
    euroController.text = valorEuro.toStringAsFixed(2);
  }
  void _dolarChanged(String text)async{
    if(text.isEmpty){
      clearAll();
      return;
    }
    var valorReal = double.parse(text) * Dolar;
    var valorEuro = valorReal / Euro;
    print("Dolar: $text");
    print("Real: $valorReal");
    print("Euro: $valorEuro");
    realController.text = valorReal.toStringAsFixed(2);
    euroController.text = valorEuro.toStringAsFixed(2);
  }
  void _euroChanged(String text)async{
    if(text.isEmpty){
      clearAll();
      return;
    }
    var valorReal = double.parse(text) * Euro;
    var valorDolar = valorReal / Dolar;
    print("Euro: $text");
    print("Dolar: $valorDolar");
    print("Real: $valorReal");
    dolarController.text = valorDolar.toStringAsFixed(2);
    realController.text = valorReal.toStringAsFixed(2);
  }
  double Dolar;
  double Euro;
  String data;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("\$ Conversor \$"),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: FutureBuilder<Map>(
        future: getVal(),
        builder: (context, snapshot){
          switch(snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(
                child:  Text("Carregando dados...",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 25.0
                  ),
                  textAlign: TextAlign.center,
                )
              );
            default:
              if(snapshot.hasError) {
                return Center(
                    child: Text("Erro! :(",
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 25.0
                      ),
                      textAlign: TextAlign.center,
                    )
                );
              }else{
                Dolar = snapshot.data['dolar'];
                Euro = snapshot.data['euro'];
                data = DateFormat("dd/MM/yyyy HH:mm:ss").format(DateTime.parse(snapshot.data['data']));
                return SingleChildScrollView(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.monetization_on,
                        size: 100.0,
                        color: Colors.amber,
                      ),
                      getInputField("Reais", "R\$ ", realController, _realChanged),
                      Divider(),
                      getInputField("Dolares", "US\$ ", dolarController, _dolarChanged),
                      Divider(),
                      getInputField("Euros", "€ ", euroController, _euroChanged),
                      IconButton(
                        tooltip: "Reset",
                        icon: Icon(
                          Icons.clear_all,
                          size: 25.0,
                          color: Colors.amber,
                        ),
                        onPressed: clearAll
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Data cotação: $data",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              size: 15.0,
                              color: Colors.amber,
                            ),
                            onPressed: (){getVal();},
                          ),
                        ]
                      )
                    ],
                  )
                );
              }
            }
          }
      ),
    );
  }
}

getInputField(String label, String prefix, TextEditingController controller, Function onChangeFunction){
  return TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.amber
            ),
            border: OutlineInputBorder(),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: Colors.amber,
              fontSize: 15.0
            )
          ),
          cursorColor: Colors.amber,
          style: TextStyle(
            color: Colors.amber,
            fontSize: 15.0
          ),
          onChanged: onChangeFunction,
        );
}

Future<Map> getVal() async {
  http.Response responseDolar = null;
  http.Response responseEuro = null;
  var failCount = 0;
  var formatter = DateFormat('MM-dd-yyyy');
  var now = DateTime.now();
  var data = formatter.format(now);
  String requestDolar = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
      "CotacaoMoedaDia(moeda=@moeda,dataCotacao=@dataCotacao)?"
      "@moeda='USD'&@dataCotacao='${data}'&\$top=100&\$format=json";
  String requestEuro = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
      "CotacaoMoedaDia(moeda=@moeda,dataCotacao=@dataCotacao)?"
      "@moeda='EUR'&@dataCotacao='${data}'&\$top=100&\$format=json";
  responseDolar = await http.get(requestDolar);
  responseEuro = await http.get(requestEuro);
  var valueDolar = jsonDecode(responseDolar.body);
  var valueEuro = jsonDecode(responseEuro.body);
  while(valueDolar['value'].length < 1 && valueEuro['value'].length < 1 && failCount < 5) {
    now = now.subtract(Duration(days: 1));
    data = formatter.format(now);
    String requestDolar = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
        "CotacaoMoedaDia(moeda=@moeda,dataCotacao=@dataCotacao)?"
        "@moeda='USD'&@dataCotacao='${data}'&\$top=100&\$format=json";
    String requestEuro = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
        "CotacaoMoedaDia(moeda=@moeda,dataCotacao=@dataCotacao)?"
        "@moeda='EUR'&@dataCotacao='${data}'&\$top=100&\$format=json";
    responseDolar = await http.get(requestDolar);
    responseEuro = await http.get(requestEuro);
    valueDolar = jsonDecode(responseDolar.body);
    valueEuro = jsonDecode(responseEuro.body);
    failCount ++;
  }
  print(requestDolar);
  print(requestEuro);
  print(responseDolar.body);
  print(responseEuro.body);
  print(data);
  print(valueDolar);
  print(valueEuro);
  if(failCount >= 5)
    throw Future.error(StackTrace);
  else {
    Map mapa = Map();
    mapa.addEntries([
      MapEntry("dolar", valueDolar['value'].last['cotacaoCompra']),
      MapEntry("euro", valueEuro['value'].last['cotacaoCompra']),
      MapEntry("data", valueDolar['value'].last['dataHoraCotacao'])
    ]);
    print(mapa);
    return mapa;
  }
}