typedef IFilterFirestore = ({
  String name,
  String url,
});

typedef ICompanyFirestore = ({
  String email,
  String name,
  /** Filters ids from collection `filters` */
  List<IFilterFirestore> filters,
  bool admin,
});
