import 'package:flutter/material.dart';
import 'package:proxmox_config/models/ServerConfiguration.dart';
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

  List<Widget> getSelectableText() {
    List<ServerConfiguration> favorites = configurations.where((config) => config.favorite).toList();
    List<ServerConfiguration> nonFavorites = configurations.where((config) => !config.favorite).toList();
    return [
      // Favorites ListWithTitle
      if (favorites.isNotEmpty)
        ListWithTitle(
          title: "Favorites",
          items: favorites
              .map((config) => proxmoxSelectableText.SelectableText(text: config.name,
              onClick: () => SetActive(config),
              ))
              .toList(),
        ),
      // Non-Favorites ListWithTitle
      if (nonFavorites.isNotEmpty)
        ListWithTitle(
          title: "Other Servers",
          items: nonFavorites
              .map((config) => proxmoxSelectableText.SelectableText(text: config.name,
              onClick: () => SetActive(config),))
              .toList(),
        ),
      IconButton(onPressed: () => addConfiguration(), icon: Icon(Icons.add))
    ];
  }

  void addConfiguration() {
    setState(() {
      ServerConfiguration newConfiguration = ServerConfiguration(name: "new Configuration");
      configurations.add(newConfiguration);
      activeConfiguration = newConfiguration;
    });
  }

  void deleteConfiguration() {
    setState(() {
      configurations.remove(activeConfiguration);
    });
  }

  List<Widget> getConfigurationFields() {
    if (activeConfiguration == null) {
      return [
        const Text("No active configuration selected."),
      ];
    }

    return [
      LabeledTextField(label: "Name", initialText:activeConfiguration!.name),
      const SizedBox(height: 10),
      LabeledTextField(label: "Host", initialText:activeConfiguration!.host),
      const SizedBox(height: 10),
      LabeledTextField(label: "Port", initialText:activeConfiguration!.port.toString()),
      const SizedBox(height: 10),
      LabeledTextField(label: "password", initialText:activeConfiguration!.idRsaPath),
    ];
  }


  void SetActive(ServerConfiguration config) {
    setState(() {
      activeConfiguration = config;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    items: getConfigurationFields(),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: deleteConfiguration,
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
