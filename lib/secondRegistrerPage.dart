import 'package:flutter/material.dart';
import 'package:dsc_solution_challenge_2020/components/containerBox.dart';
import 'package:dsc_solution_challenge_2020/components/customAppBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dsc_solution_challenge_2020/components/alertPopup.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'dart:math';

class SecondRegisterPage extends StatefulWidget {
  SecondRegisterPage(
      {this.name, this.age, this.address, this.number, this.gender});

  final String name;
  final String age;
  final String address;
  final String number;
  final String gender;

  @override
  _SecondRegisterPageState createState() => _SecondRegisterPageState();
}

class _SecondRegisterPageState extends State<SecondRegisterPage> {
  String etcInfo;

  final _firestore = Firestore.instance;
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;
  String currentEmail;
  String profileImageURL =
      "gs://dsc-solution-challenge-6c028.appspot.com/photo/";
  String timeVar = DateTime.now().year.toString() + "_" + DateTime.now().month.toString() + "_" + DateTime.now().day.toString() + "_" + DateTime.now().hour.toString() + "_" + DateTime.now().minute.toString() +  "_";
  int randomNumber;
  File _image;
  String imageType;
  

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        currentEmail = loggedInUser.email;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool showSpinner = false;

    Future getImage() async {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      int fileLength = await image.length();
      if (fileLength > 2499999) {
        alertPopup(context, 7);
      } else {
        setState(() {
          imageType = extension(image.path).toUpperCase();
          _image = image;
        });
      }
    }

    Future uploadPic(BuildContext context) async {
      randomNumber = Random().nextInt(10000) + 1;
      StorageReference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child("photo/$timeVar$randomNumber$imageType");
      StorageUploadTask uploadTask = firebaseStorageRef.putFile(_image);
      StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomPadding: false,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SingleChildScrollView(
          child: Container(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(10.0),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ContainerBox(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Other matters',
                          style: TextStyle(
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextField(
                          onChanged: (value) {
                            etcInfo = value;
                          },
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                          maxLines: 12,
                          keyboardType: TextInputType.text, //줄바꿈
                          decoration: InputDecoration(
                            hintText:
                                "Write family information, social participation, economic status, residential environment, disease, major needs, etc.",
                            labelStyle:
                                TextStyle(fontSize: 20.0, color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 20.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ContainerBox(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 60.0,
                          child: ClipOval(
                            child: new SizedBox(
                              width: 180.0,
                              height: 180.0,
                              child: (_image != null)
                                  ? Image.file(
                                      _image,
                                      fit: BoxFit.fill,
                                    )
                                  : Image.asset('images/DSCHUFS.png',
                                      fit: BoxFit.fill,
                                    ),
                            ),
                          ),
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.add_a_photo,
                              size: 40.0,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              getImage();
                            }),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 50.0, vertical: 10.0),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        if (etcInfo == null || etcInfo == '') {
                          alertPopup(context, 8);
                        } else {
                          setState(() {
                            showSpinner = true;
                          });
                          if(_image != null){
                            await uploadPic(context);
                          }
                          setState(() {
                            if(_image == null){
                              profileImageURL = "gs://dsc-solution-challenge-6c028.appspot.com/photo/IMG_5862.PNG";
                            }
                            else {
                              profileImageURL += "$timeVar$randomNumber$imageType";
                            }
                          });
                          
                          await _firestore
                              .collection('Accounts')
                              .document(currentEmail)
                              .collection('ElderInfo')
                              .document(widget.name)
                              .setData({
                            'name': widget.name,
                            'gender': widget.gender,
                            'address': widget.address,
                            'phoneNum': widget.number,
                            'IdNum': widget.age,
                            'note': etcInfo,
                            'photo': profileImageURL,
                          });
                          print('picURL $profileImageURL');
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => CustomAppBar()),
                              (Route<dynamic> route) => false);
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
