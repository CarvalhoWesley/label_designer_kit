/// Transporte de impressão reutilizável: `PrintTransport`/`PrinterDiscovery`
/// — abstrai "enviar bytes já renderizados para uma impressora física" para
/// que o framework não fique preso a um pacote de terceiros específico de
/// uma plataforma. Consumido apenas pelo projeto do usuário (ver
/// `docs/ROADMAP.md`, "Extensões futuras" e etapa 20), nunca pelo domínio.
///
/// Este pacote só define o contrato — os backends concretos (ex.:
/// `label_print_transport_windows`, embrulhando o spooler do Windows) são
/// pacotes irmãos, seguindo o mesmo padrão de `label_renderer` (contrato)
/// + `label_renderer_argox`/`_zebra`/`_tsc` (backends).
library;

export 'src/print_transport.dart';
export 'src/print_transport_exception.dart';
export 'src/printer_discovery.dart';
