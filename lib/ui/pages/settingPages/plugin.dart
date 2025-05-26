import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PluginPage extends StatefulWidget {
  const PluginPage({super.key});

  @override
  State<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> with TickerProviderStateMixin {
  @override
  initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getProviders();
  }

  final _providerManager = ProviderManager();

  late TabController _tabController;

  List<ProviderDetails>? _availableProviders = null;
  List<ProviderDetails>? _installedProviders = null;

  Future<void> getProviders() async {
    final saved = await _providerManager.getSavedProviders();
    setState(() {
      _installedProviders = saved;
    });

    if(kDebugMode)
    _providerManager.fetchProvidersRepo().then((val) {
      final savedSet = saved.map((e) => e.identifier).toSet();
      val.removeWhere((it) => savedSet.contains(it.identifier));
      setState(() {
        _availableProviders = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: MediaQuery.paddingOf(context),
        child: 
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: appTheme.textMainColor,
                            size: 28,
                          )),
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 20),
                        child: Text(
                          "Manage Providers [Beta]",
                          style: TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  IconButton(onPressed: () {}, icon: Icon(Icons.science_sharp, size: 25, color: appTheme.textMainColor,))
                ],
              ),
            ),

            Expanded(child: Center(child: Text("Should arrive soon!"),))
            
            // TabBar(
            //   controller: _tabController,
            //   labelColor: appTheme.accentColor,
            //   indicatorColor: appTheme.accentColor,
            //   unselectedLabelColor: appTheme.textSubColor,
            //   labelStyle: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     fontFamily: "NotoSans",
            //   ),
            //   // dividerHeight: 0,
            //   // indicatorSize: TabBarIndicatorSize.tab,
            //   tabs: [
            //     Container(
            //         height: 50,
            //         alignment: Alignment.center,
            //         child: Text(
            //           "Installed",
            //           style: _textStyle(),
            //         )),
            //     Container(height: 50, alignment: Alignment.center, child: Text("Available", style: _textStyle())),
            //   ],
            // ),
            // Expanded(
            //     child: TabBarView(
            //   controller: _tabController,
            //   children: [
            //     _installedProviders == null
            //         ? Center(child: AnimeStreamLoading(color: appTheme.accentColor))
            //         : _list(_installedProviders!),
            //     _availableProviders == null
            //         ? Center(child: AnimeStreamLoading(color: appTheme.accentColor))
            //         : _list(_availableProviders!),
            //   ],
            // )),
          ],
        ),
      ),
    );
  }

  Widget _list(List<ProviderDetails> data) {
    return data.isEmpty
        ? Center(child: Text("Nothing to see here..."))
        : ListView.builder(
            padding: EdgeInsets.only(top: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: appTheme.backgroundSubColor,
                ),
                clipBehavior: Clip.hardEdge,
                child: Row(
                  children: [
                    ClipRRect(
                      child: item.icon != null
                          ? CachedNetworkImage(
                              imageUrl: item.icon!,
                              alignment: Alignment.center,
                              height: 75,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text("v" + item.version),
                        ],
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: TextButton(
                        onPressed: () async {
                          // item.code can indicate the install status.
                          //since we are only storing the code when plugin is installed
                          if (item.code == null) {
                            try {
                              final code = await _providerManager.fetchProviderCode(item.identifier);
                              if (code == null) floatingSnackBar("couldnt install the provider. Install failed");
                              await _providerManager.saveProvider(item.copyWith(code: code));
                              getProviders();
                            } catch (err) {
                              print(err);
                              floatingSnackBar("Install failed. Failed to fetch the code.");
                              if (currentUserSettings?.showErrors ?? false)
                                floatingSnackBar(err.toString(), waitForPreviousToFinish: true);
                            }
                          } else {
                            await _providerManager.removeProvider(item);
                            getProviders();
                          }
                        },
                        child: Text(item.code == null ? "install" : "remove"),
                        style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            backgroundColor: appTheme.accentColor,
                            foregroundColor: appTheme.onAccent),
                      ),
                    )
                  ],
                ),
              );
            });
  }

  TextStyle _textStyle() {
    return TextStyle(
      // color: appTheme.textMainColor,
      fontFamily: "NotoSans-Bold",
      fontSize: 17,
    );
  }
}
