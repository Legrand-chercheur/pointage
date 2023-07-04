import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'acceuil_liste_code.dart';


class details extends StatefulWidget {
  var response;
  details({this.response});

  @override
  State<details> createState() => _detailsState();
}
class _detailsState extends State<details> {

  var heure_debut = '';
  var heure_fin = '';

  void heure_travail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id_entreprise = prefs.getString('id');

    final uri = Uri.parse('http://lea241.alwaysdata.net/pointage/controller_api.php');
    var reponse = await http.post(uri, body: {
      'clic': 'heure_travails',
      'entrepriseId': id_entreprise,
    });
    var datas = reponse.body.split(',');

    setState(() {
      if (datas.length >= 2) {
        heure_debut = datas[0];
        heure_fin = datas[1];
      } else {
        heure_debut = 'Heure de début non disponible';
        heure_fin = 'Heure de fin non disponible';
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    heure_travail();
  }
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    heure_travail();
    String reponse = widget.response;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/connexion.png'),
                fit: BoxFit.cover
            )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(reponse.split(',')[0]+' !',style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold
            ),),
            Text('Track planifie de '+heure_debut+' a '+heure_fin,style: TextStyle(
              color: Colors.white,
              fontSize: 15
            ),),
            Text('18:32',style: TextStyle(
                color: Colors.white,
                fontSize: 80
            ),),
            Text(reponse.split(',')[1]+'.',style: TextStyle(
                color: Colors.white,
                fontSize: 15
            ),),
            SizedBox(height: 10,),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page_acceuil()),
                );
              },
              child: Container(
                width: size.width/3,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Center(
                  child: Text('Demarrer mon pointage'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
