import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:pip_services3_commons/pip_services3_commons.dart';
import 'package:pip_services3_rpc/pip_services3_rpc.dart';

import '../dummy/Dummy.dart';
import '../dummy/DummySchema.dart';
import '../logic/IDummyController.dart';

class DummyRestService extends RestService {
  late IDummyController controller;

  DummyRestService() : super() {
    dependencyResolver.put('controller',
        Descriptor('pip-services-dummies', 'controller', 'default', '*', '*'));
  }

  @override
  void setReferences(IReferences references) {
    super.setReferences(references);
    controller = dependencyResolver.getOneRequired('controller');
  }

  @override
  void configure(ConfigParams config) {
    super.configure(config);
  }

  FutureOr<Response> _getPageByFilter(Request req) async {
    var result = await controller.getPageByFilter(
        getCorrelationId(req),
        FilterParams(req.url.queryParameters),
        PagingParams(req.url.queryParameters));

    return await sendResult(req, result);
  }

  FutureOr<Response> _getOneById(Request req) async {
    var result = await controller.getOneById(
        getCorrelationId(req), req.params['dummy_id']!);
    return await sendResult(req, result);
  }

  FutureOr<Response> _create(Request req) async {
    var dummy = Dummy.fromJson(json.decode(await req.readAsString()));
    var result = await controller.create(getCorrelationId(req), dummy);
    return await sendCreatedResult(req, result);
  }

  FutureOr<Response> _update(Request req) async {
    var dummy = Dummy.fromJson(json.decode(await req.readAsString()));
    var result = await controller.update(getCorrelationId(req), dummy);
    return await sendResult(req, result);
  }

  FutureOr<Response> _deleteById(Request req) async {
    var result = await controller.deleteById(
        getCorrelationId(req), req.params['dummy_id']!);
    return await sendDeletedResult(req, result);
  }

  FutureOr<Response> _checkCorrelationId(Request req) async {
    try {
      var result = await controller.checkCorrelationId(getCorrelationId(req));
      return await sendResult(req, {'correlation_id': result});
    } catch (ex) {
      return await sendError(req, ex);
    }
  }

  @override
  void register() {
    registerRoute(
        'get',
        '/dummies',
        ObjectSchema(true)
            .withOptionalProperty('skip', TypeCode.String)
            .withOptionalProperty('take', TypeCode.String)
            .withOptionalProperty('total', TypeCode.String)
            .withOptionalProperty('body', FilterParamsSchema()),
        _getPageByFilter);

    registerRoute('get', '/dummies/check/correlation_id', ObjectSchema(true),
        _checkCorrelationId);

    registerRoute(
        'get',
        '/dummy/<dummy_id>',
        ObjectSchema(true).withRequiredProperty('dummy_id', TypeCode.String),
        _getOneById);

    registerRoute(
        'post',
        '/dummies',
        ObjectSchema(true).withRequiredProperty('body', DummySchema()),
        _create);

    registerRoute(
        'put',
        '/dummy/<dummy_id>',
        ObjectSchema(true).withRequiredProperty('body', DummySchema()),
        _update);

    registerRoute(
        'delete',
        '/dummy/<dummy_id>',
        ObjectSchema(true).withRequiredProperty('dummy_id', TypeCode.String),
        _deleteById);

    swaggerRoute = '/dummies/swagger';

    registerOpenApiSpecFromFile(
        Directory.current.path + '/example/services/dummy.yml');
  }
}
