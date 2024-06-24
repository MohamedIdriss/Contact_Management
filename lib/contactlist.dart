import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:gestion_contact/sql_helper.dart';
import 'package:gestion_contact/update_contact_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'add_contact_page.dart';


class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> contacts = [];


  TextEditingController searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _getContacts();
  }

  Future<void> _getContacts() async {
    List<Map<String, dynamic>> fetchedContacts = await dbHelper.getContacts();
    setState(() {
      contacts = fetchedContacts;
      _filteredContacts=contacts;
    });
  }

  void _addContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactPage(),
      ),
    );

    _getContacts();
  }

  void _updateContact(int contactId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateContactPage(contactId: contactId),
      ),
    );

    _getContacts();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (await Permission.phone.request().isGranted) {
      final url = 'tel:$phoneNumber';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      throw 'The CALL_PHONE permission is not granted.';
    }
  }
  List<Map<String, dynamic>> _filteredContacts = [];

  void filterContacts(String query) {
    setState(() {
      _filteredContacts=contacts.where((contact)=>
      contact['tel'].toString().toLowerCase().contains(query.toLowerCase()) ||
          contact['nom'].toString().toLowerCase().contains(query.toLowerCase())
          ||
          contact['prenom'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  void _deleteContact(int contactId) async {

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Souhaitez-vous vraiment supprimer cet Contact?',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w500,
            fontSize: 18.0,
          ),
        ),

        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              int rowsAffected = await dbHelper.deleteContact(contactId);
              print('Deleted $rowsAffected contact(s)');
              _getContacts();
            },
            child: Text(
              'SUPPRIMER',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'ANNULER',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ],
      ),
    );

  }
  int _isfavorited = 0;

  void _toggleFavorite(int ContactId) async {

    setState(() {
      if (_isfavorited == 0) {
        _isfavorited= 1;
      } else {
        _isfavorited = 0;
      }
    });
print(_isfavorited);
    await dbHelper.favorisContact(ContactId, _isfavorited);
    await _getContacts();
     filterContacts(searchController.text);
  }
  bool textFieldVisible =false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: textFieldVisible
            ? Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            cursorColor: Colors.black,
            controller: searchController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(Icons.cancel, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _getContacts();
                    textFieldVisible = false;
                    searchController.text = '';
                  });
                },
              ),
            ),
            onChanged: (String value) {
              print(value);
              filterContacts(value);
            },
          ),
        )
            : Center(child: Text('Contacts')),
        actions: [
          Visibility(
            visible: !textFieldVisible,
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  textFieldVisible = true;

                });
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredContacts.length,
        itemBuilder: (BuildContext context, int index) {
          String photoPath = _filteredContacts[index]['photo'];
          File imageFile = File(photoPath);
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: photoPath != ''
                  ? CircleAvatar(
                backgroundImage: FileImage(imageFile),
                radius: 24,
              )
                  : CircleAvatar(
                backgroundColor: Colors.blue[400],
                child: Text(
                  _filteredContacts[index]['prenom'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                radius: 24,
              ),
              title: Text(
                '${_filteredContacts[index]['prenom']} ${_filteredContacts[index]['nom']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _filteredContacts[index]['tel'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () => _deleteContact(_filteredContacts[index]['id']),
                  ),
            IconButton(
              icon: _filteredContacts[index]['isfavorite']==0
                  ? Icon(Icons.favorite, color: Colors.yellow)
                  : Icon(Icons.favorite_border),
              onPressed: () => _toggleFavorite((_filteredContacts[index]['id']),
              ),),
                  IconButton(
                    icon: Icon(
                      Icons.call,
                      color: Colors.green,
                    ),
                    onPressed: (){
                      Uri launchUri = Uri(
                        scheme: 'tel',
                        path: _filteredContacts[index]['tel'],
                      );
                      launchUrl(launchUri);
                    },
                  ),
                ],
              ),
              onTap: () => _updateContact(_filteredContacts[index]['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[900],
        child: Icon(Icons.add),
        onPressed: _addContact,
      ),
    );
  }
}