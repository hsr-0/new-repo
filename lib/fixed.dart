// mock_debug_panel.dart

class WidgetClassDebugData {
  WidgetClassDebugData({
    dynamic generatorVariables,
    dynamic backendQueries,
    dynamic componentStates,
    dynamic dynamicWidgetClassDebugData,
  });
}

class DebugGeneratorVariables {
  DebugGeneratorVariables({dynamic debugDataFields});
}

class DebugBackendQueries {
  DebugBackendQueries({dynamic debugDataFields});
}

class DynamicWidgetClassDebugData {
  DynamicWidgetClassDebugData({dynamic debugDataFields});
}

dynamic debugSerializeParam(
    dynamic param,
    dynamic paramType, {
      dynamic link,
      dynamic searchReference,
    }) => param;