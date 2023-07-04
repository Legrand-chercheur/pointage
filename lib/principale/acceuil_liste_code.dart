import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/liste_employes.dart';
import 'information_pointage.dart';

class page_acceuil extends StatefulWidget {

  @override
  State<page_acceuil> createState() => _page_acceuilState();
}

List<Employes> _List_Employe = <Employes>[];

Future<List<Employes>> Recuperer_Employe() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? id_entreprise = prefs.getString('id');
  final uri = Uri.parse('http://lea241.alwaysdata.net/pointage/controller_api.php');
  var reponse = await http.post(uri, body: {
    'clic': 'employer',
    'id_entreprise': id_entreprise,
  });
  var nouveau = <Employes>[];
  final datas = json.decode(reponse.body);
  print(datas);
  for (var data in datas) {
    nouveau.add(Employes.fromjson(data));
  }
  return nouveau;
}

class _page_acceuilState extends State<page_acceuil> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  int selectedIndex = -1;
  String selectedEmployeeId = '';
  String enteredCode = '';
  bool isCodeComplete = false;

  snackbar (text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content:Text(text,style: TextStyle(
          color: Colors.white
      ),),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void pointage(id_employe, id_entreprise, image, prenom) async {
    final uri = Uri.parse('http://lea241.alwaysdata.net/pointage/controller_api.php');
    var reponse = await http.post(uri, body: {
      'clic': 'pointer',
      'id_employe': id_employe,
      'entreprise': id_entreprise,
      'image': image,
      'prenom': prenom,
    });
    if(reponse.body == 'Le pointeur a rencontre un petit probleme'){
      snackbar('Le pointeur a rencontre un petit probleme');
    }
    else if(reponse.body == 'probleme'){
      snackbar('probleme');
    }
    else if(reponse.body == '0'){
      snackbar('0');
    }
    else {
      //Rediriger vers une autre page lorsque le code est complet et correct
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => details(response: reponse.body,)),
      );
    }
  }

  void verification(code, id_employe) async {
    final uri = Uri.parse('http://lea241.alwaysdata.net/pointage/controller_api.php');
    var reponse = await http.post(uri, body: {
      'clic': 'verify',
      'id_employe': id_employe,
      'code': code,
    });
    if(reponse.body == 'non'){
      snackbar('Ceci n\'est pas votre mot de passe');
      resetCode();
    }else{
      var data = reponse.body;
      if (!_controller!.value.isInitialized) {
        return;
      }

      try {
        final XFile photo = await _controller!.takePicture();
        // Upload the photo file to the server
        pointage(data.split(',')[0], data.split(',')[2], photo.name, data.split(',')[1]);
        resetCode();
        await uploadPhoto(photo.path);
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> setupCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[1], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> uploadPhoto(String imagePath) async {
    final String apiUrl = 'http://lea241.alwaysdata.net/pointage/uploading.php'; // Replace with your API endpoint
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
    var response = await request.send();

    if (response.statusCode == 200) {
      // Photo uploaded successfully
      print(response.headers);
    } else {
      // Error uploading photo
      print('Error uploading photo. Status code: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    setupCamera();
    Recuperer_Employe().then((value) {
      setState(() {
        _List_Employe.addAll(value);
      });
    });
  }

  void handleNumericButtonPress(String value) {
    setState(() {
      if (enteredCode.length < 4) {
        enteredCode += value;
        if (enteredCode.length == 4) {
          isCodeComplete = true;
          verification(enteredCode, selectedEmployeeId);
        }
      }
    });
  }

  void resetCode() {
    setState(() {
      enteredCode = '';
      isCodeComplete = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width / 2,
            height: size.height,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: ListView.builder(
              itemCount: _List_Employe.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                            selectedEmployeeId = _List_Employe[index].id;
                          });
                        },
                        child: Container(
                          width: size.width / 1.2,
                          height: 60,
                          color: index == selectedIndex ? Colors.white : null,
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: NetworkImage('http://192.168.100.75:5000/'+_List_Employe[index].photo),
                                      fit: BoxFit.cover
                                  ),
                                  borderRadius: BorderRadius.circular(100)
                                ),
                                width: 60,
                                height: 60,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Column(
                                children: [
                                  Text(_List_Employe[index].nom +
                                      ' ' +
                                      _List_Employe[index].prenom),
                                  Text(_List_Employe[index].poste),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider()
                  ],
                );
              },
            ),
          ),
          Container(
            width: size.width / 2,
            height: size.height,
            decoration: BoxDecoration(color: Colors.white),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  selectedIndex != -1
                      ? Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CodeDot(isFilled: enteredCode.length >= 1),
                          CodeDot(isFilled: enteredCode.length >= 2),
                          CodeDot(isFilled: enteredCode.length >= 3),
                          CodeDot(isFilled: enteredCode.length >= 4),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: size.width/2.8,
                        child: Divider(),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          NumericButton(value: '1', onPressed: handleNumericButtonPress),
                          NumericButton(value: '2', onPressed: handleNumericButtonPress),
                          NumericButton(value: '3', onPressed: handleNumericButtonPress),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          NumericButton(value: '4', onPressed: handleNumericButtonPress),
                          NumericButton(value: '5', onPressed: handleNumericButtonPress),
                          NumericButton(value: '6', onPressed: handleNumericButtonPress),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          NumericButton(value: '7', onPressed: handleNumericButtonPress),
                          NumericButton(value: '8', onPressed: handleNumericButtonPress),
                          NumericButton(value: '9', onPressed: handleNumericButtonPress),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NumericButton(value: '0', onPressed: handleNumericButtonPress),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  )
                      : Text('Cliquez sur votre nom pour pointer'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class NumericButton extends StatelessWidget {
  final String value;
  final Function(String) onPressed;

  const NumericButton({required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: () => onPressed(value),
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          primary: Colors.grey[200],
        ),
        child: Text(
          value,
          style: TextStyle(fontSize: 24,color: Colors.black),
        ),
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const RoundedButton({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          primary: color,
        ),
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class CodeDot extends StatelessWidget {
  final bool isFilled;

  const CodeDot({required this.isFilled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? Colors.grey : Colors.transparent,
        border: Border.all(color: Colors.grey),
      ),
    );
  }
}
