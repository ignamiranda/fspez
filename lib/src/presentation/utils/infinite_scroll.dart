import 'package:flutter/material.dart';

typedef LoadMoreFn = void Function();

ScrollController createInfiniteScrollController(
    LoadMoreFn loadMore, {double threshold = 300.0}) {
  final controller = ScrollController();
  controller.addListener(() {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - threshold) {
      loadMore();
    }
  });
  return controller;
}
