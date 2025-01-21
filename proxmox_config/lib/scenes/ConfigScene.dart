import 'package:flutter/material.dart';
import 'package:proxmox_config/models/ServerConfiguration.dart';
import 'package:proxmox_config/scenes/ServerScene.dart';
import 'package:proxmox_config/utils/SSHUtils.dart';
import 'package:proxmox_config/utils/SaveUtils.dart';
import 'package:proxmox_config/widgets/CustomButton.dart';
import 'package:proxmox_config/widgets/FileSelectorField.dart';
import 'package:proxmox_config/widgets/ListWithTitle.dart';
import 'package:proxmox_config/widgets/LabeledTextField.dart';
import 'package:proxmox_config/widgets/SelectableText.dart' as proxmoxSelectableText;

class ConfigScene extends StatefulWidget {
  ConfigScene({Key? key}) : super(key: key);

  @override
  _ConfigSceneState createState() => _ConfigSceneState();
}

class _ConfigSceneState extends State<ConfigScene> {
  List<ServerConfiguration> configurations = [];
  ServerConfiguration? activeConfiguration;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final FileSelectorController passwordController = FileSelectorController();
  
  @override
  void initState() {
    super.initState();
    List<dynamic> saveData = SaveUtils.load("configurations.json");
    if (saveData.isNotEmpty) {
      for (dynamic config in saveData) {
        try{
          ServerConfiguration newConfig = ServerConfiguration.fromJson(config as Map<String, dynamic>);
          configurations.add(newConfig);
        } catch(e) {
          print("Error loading configurations: $e");
          print(config);
        }
      }
    }
    setControllerListeners();
  }

  Future<void> saveConfigurations() async {
    await SaveUtils.saveAsync("configurations.json", configurations);
  }

  void setControllerListeners() {
    nameController.addListener(() {
      if (activeConfiguration != null) {
        setState(() {
          activeConfiguration!.name = nameController.text;//Changes the name displayed in the list
        });
        saveConfigurations();
      }
    });

    hostController.addListener(() {
      if (activeConfiguration != null) {
        activeConfiguration!.host = hostController.text;
        saveConfigurations();
      }
    });

    usernameController.addListener(() {
      if (activeConfiguration != null) {
        activeConfiguration!.username = usernameController.text;
        saveConfigurations();
      }
    });

    portController.addListener(() {
      if (activeConfiguration != null) {
        // Ensure port is a valid integer
        final int? port = int.tryParse(portController.text);
        if (port != null) {
          activeConfiguration!.port = port;
          saveConfigurations();
        }
      }
    });

    passwordController.addListener(() {
      if (activeConfiguration != null) {
        activeConfiguration!.idRsaPath = passwordController.selectedFilePath ?? "";
        saveConfigurations();
      }
    });
  }

  void updateControllers() {
    if (activeConfiguration != null) {
      nameController.text = activeConfiguration!.name;
      hostController.text = activeConfiguration!.host;
      usernameController.text = activeConfiguration!.username;
      portController.text = activeConfiguration!.port.toString();
      passwordController.selectedFilePath = activeConfiguration!.idRsaPath;
    } else {
      nameController.clear();
      hostController.clear();
      usernameController.clear();
      portController.clear();
      passwordController.clear();
    }
  }

  void addConfiguration() {
    setState(() {
      ServerConfiguration newConfiguration = ServerConfiguration(name: "new Configuration");
      configurations.add(newConfiguration);
      SetActive(newConfiguration);
    });
  }

  void deleteConfiguration() {
    setState(() {
      configurations.remove(activeConfiguration);
      activeConfiguration = null;
      updateControllers();
    });
  }

  void connectToServer() async {

    SSHUtils.connect(
      host: hostController.text,
      username: usernameController.text,
      keyFilePath: passwordController.selectedFilePath ?? "",
      port: int.parse(portController.text),
    ).then((value) => {
      print("connected"),
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ServerScene(),
        ),
      )
    });
  }

  void setFavorite() {
    setState(() {
      if (activeConfiguration != null) {
        activeConfiguration!.favorite = !activeConfiguration!.favorite;
      }
    });
  }

  void SetActive(ServerConfiguration config) {
    setState(() {
      activeConfiguration = config;
      updateControllers();
    });
  }

  List<Widget> getConfigurationFields() {
    if (activeConfiguration == null) {
      return [
        const Text("No active configuration selected."),
      ];
    }
    return [
      LabeledTextField(label: "Name", controller: nameController),
      const SizedBox(height: 10),
      LabeledTextField(label: "Host", controller: hostController),
      const SizedBox(height: 10),
      LabeledTextField(label: "user", controller: usernameController),
      const SizedBox(height: 10),
      LabeledTextField(label: "Port", controller: portController),
      const SizedBox(height: 10),
      FileSelectorField(label: "Password", controller: passwordController),
    ];
  }
  
  List<Widget> getSelectableText() {
    List<ServerConfiguration> favorites = configurations.where((config) => config.favorite).toList();
    List<ServerConfiguration> nonFavorites = configurations.where((config) => !config.favorite).toList();
    List<Widget> favoriteText = [];
    List<Widget> otherText = [];

    for (ServerConfiguration config in favorites) {
      proxmoxSelectableText.SelectableText selectableText = proxmoxSelectableText.SelectableText(
        text: config.name,
        onClick: () => SetActive(config),
        isSelected: activeConfiguration == config,
      );
      favoriteText.add(selectableText);
    }

    for (ServerConfiguration config in nonFavorites) {
      proxmoxSelectableText.SelectableText selectableText = proxmoxSelectableText.SelectableText(
        text: config.name,
        onClick: () => SetActive(config),
        isSelected: activeConfiguration == config,
      );
      otherText.add(selectableText);
    }


    return [
      if (favorites.isNotEmpty)
        ListWithTitle(
          title: "Favorites",
          items: favoriteText,
        ),
      if (nonFavorites.isNotEmpty)
        ListWithTitle(
          title: "Other Servers",
          items: otherText,
        ),

      IconButton(onPressed: () => addConfiguration(), icon: Icon(Icons.add))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: ListWithTitle(
                title: "Servidors",
                items: getSelectableText(),
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListWithTitle(
                      title: "Configuracio SSH",
                      items: [...getConfigurationFields(),const SizedBox(height: 10),
                      if (activeConfiguration != null)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                          children: [
                            CustomButton(
                              text: "Delete",
                              color: Colors.red,
                              onPressed: deleteConfiguration,
                            ), 
                            const SizedBox(width: 10),
                            CustomButton(
                              text: "Add to favoirites",
                              color: Colors.yellow,
                              onPressed: setFavorite,
                              textStyle: const TextStyle(color: Colors.black),
                            ), 
                            const SizedBox(width: 10),
                            CustomButton(
                              text: "Connect",
                              color: Colors.lightGreen,
                              onPressed: connectToServer,
                            ), 
                          ],
                        ),
                      )],
                    ),
                  ),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

