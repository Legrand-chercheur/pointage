import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../principale/acceuil_liste_code.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

TextEditingController email = TextEditingController();
TextEditingController passe = TextEditingController();

class _ConnexionState extends State<Connexion> {
  snackbar (text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content:Text(text,style: TextStyle(
          color: Colors.white
      ),),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void connexion(email, password) async{
    final uri = Uri.parse('http://lea241.alwaysdata.net/pointage/controller_api.php');
    var reponse = await http.post(uri, body: {
      'clic': 'con_entreprise',
      'email': email,
      'passe': password,
    });
    print(reponse.body);
    if(email == '' || password =='') {
      snackbar('Les champs sont vide');
    }else {
      if(reponse.body == 'non'){
        snackbar('Compte inconnu');
      } else {
        final datas = reponse.body.split(',');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('id', datas[0]);
        prefs.setString('entreprise', datas[1]);
        prefs.setString('logo', datas[2]);
        Navigator.push(context, MaterialPageRoute(builder: (context)=>page_acceuil()));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
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
            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 19),
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'exemple@time.track',
                    hintStyle: TextStyle(
                          color: Colors.grey
                      ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 19),
                child: TextField(
                  controller: passe,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                      hintText: 'votre mot de passe',
                      hintStyle: TextStyle(
                        color: Colors.grey
                      )
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            GestureDetector(
              onTap: (){
                connexion(email.text, passe.text);
              },
              child: Container(
                width: 300,
                height: 50,
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Center(
                  child: Text('Connexion', style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
