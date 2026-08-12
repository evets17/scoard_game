class HomeShellModel {
  const HomeShellModel({
    required this.appName,
    required this.tagline,
    required this.primaryActions,
  });

  final String appName;
  final String tagline;
  final List<HomeActionModel> primaryActions;
}

class HomeActionModel {
  const HomeActionModel({
    required this.route,
    required this.title,
    required this.icon,
    this.arguments,
  });

  final String route;
  final String title;
  final String icon;
  final Object? arguments;
}