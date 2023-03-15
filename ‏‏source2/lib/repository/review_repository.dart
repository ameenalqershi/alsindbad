import 'package:akarak/api/api.dart';
import 'package:akarak/blocs/bloc.dart';
import 'package:akarak/models/model.dart';

class ReviewRepository {
  ///Fetch api getReview
  static Future<List?> loadReview(id) async {
    final response = await Api.requestReview({"productId": id});
    if (response.succeeded) {
      final listComment = List.from(response.data['reviews'] ?? []).map((item) {
        return CommentModel.fromJson(item);
      }).toList();
      final rating = RateModel.fromJson(response.data['ratingMeta']);
      return [listComment, rating];
    }
    AppBloc.messageCubit.onShow(response.message);
    return null;
  }

  ///Fetch save review
  static Future<bool> saveReview({
    required int id,
    required int productId,
    required String content,
    required double rate,
  }) async {
    final params = {
      "id": id,
      "productId": productId,
      "content": content,
      "rating": rate,
    };
    final response = await Api.requestSaveReview(params);
    AppBloc.messageCubit.onShow(response.message);
    if (response.succeeded) {
      return true;
    }
    return false;
  }

  ///Fetch remove review
  static Future<bool> removeReview({
    required int id,
  }) async {
    final response = await Api.requestRemoveReview(id);
    AppBloc.messageCubit.onShow(response.message);
    if (response.succeeded) {
      return true;
    }
    return false;
  }

  ///Fetch save replay
  static Future<bool> saveReplay({
    required int id,
    required int reviewId,
    required String content,
  }) async {
    final params = {
      "id": id,
      "reviewId": reviewId,
      "content": content,
    };
    final response = await Api.requestSaveReplay(params);
    AppBloc.messageCubit.onShow(response.message);
    if (response.succeeded) {
      return true;
    }
    return false;
  }

  ///Fetch remove review
  static Future<bool> removeReplay({
    required int id,
  }) async {
    final response = await Api.requestRemoveReplay(id);
    AppBloc.messageCubit.onShow(response.message);
    if (response.succeeded) {
      return true;
    }
    return false;
  }

  ///Fetch author review
  static Future<ResultApiModel> loadAuthorReview({
    required int pageNumber,
    required int pageSize,
    required String searchString,
    required String createdBy,
  }) async {
    Map<String, dynamic> params = {
      "pageNumber": pageNumber,
      "pageSize": pageSize,
      "searchString": searchString,
      "createdBy": createdBy,
    };
    return await Api.requestAuthorReview(params);
  }
}
