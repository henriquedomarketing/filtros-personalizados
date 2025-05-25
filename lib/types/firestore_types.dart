typedef IFilterFirestore = ({
  String name,
  String url,
});

typedef ICompanyFirestore = ({
  String login,
  String name,
  String password,
  /** Filters ids from collection `filters` */
  List<IFilterFirestore> filters,
  bool admin,
});
