{******************************************************************************}
{ Projeto: Componente ACBrNFe                                                  }
{  Biblioteca multiplataforma de componentes Delphi para emiss�o de Nota Fiscal}
{ eletr�nica - NFe - http://www.nfe.fazenda.gov.br                             }

{ Direitos Autorais Reservados (c) 2008 Wemerson Souto                         }
{                                       Daniel Simoes de Almeida               }
{                                       Andr� Ferreira de Moraes               }

{ Colaboradores nesse arquivo:                                                 }

{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do Projeto ACBr     }
{ Componentes localizado em http://www.sourceforge.net/projects/acbr           }


{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }

{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }

{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }

{ Daniel Sim�es de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{              Pra�a Anita Costa, 34 - Tatu� - SP - 18270-410                  }

{******************************************************************************}

{$I ACBr.inc}

unit ACBrDFeWebService;

interface

uses Classes, SysUtils,
  {$IFNDEF NOGUI}
   {$IFDEF CLX} QDialogs,{$ELSE} Dialogs,{$ENDIF}
  {$ENDIF}
  HTTPSend,  // OpenSSL
  {$IFDEF SoapHTTP}
  SoapHTTPClient, SOAPHTTPTrans, SOAPConst, WinInet, ACBrCAPICOM_TLB,
  {$ELSE}
  ACBrHTTPReqResp,
  {$ENDIF}
  ACBrDFeConfiguracoes, ACBrDFe;

const
  INTERNET_OPTION_CLIENT_CERT_CONTEXT = 84;

type

  { TDFeWebService }

  TDFeWebService = class
  private
    procedure ConfiguraHTTP(HTTP: THTTPSend; Action: String);
    {$IFDEF SoapHTTP}
    procedure ConfiguraReqResp(ReqResp: THTTPReqResp);
    procedure OnBeforePost(const HTTPReqResp: THTTPReqResp; Data: Pointer);
    {$ELSE}
    procedure ConfiguraReqResp(ReqResp: TACBrHTTPReqResp);
    {$ENDIF}
  protected
    FSoapVersion: String;
    FSoapEnvelopeAtributtes: String;
    FHeaderElement: String;
    FBodyElement: String;

    FCabMsg: String;
    FDadosMsg: String;
    FEnvelopeSoap: String;
    FRetornoWS: String;
    FRetWS: String;
    FMsg: String;
    FURL: String;
    FConfiguracoes: TConfiguracoes;
    FDFeOwner: TACBrDFe;
    FArqEnv: String;
    FArqResp: String;
    FServico: String;
    FSoapAction: String;
  protected
    procedure FazerLog(Msg: AnsiString; Exibir: Boolean = False);
    procedure GerarException(Msg: String);

    procedure InicializarServico; virtual;
    procedure DefinirServicoEAction; virtual;
    procedure DefinirURL; virtual;
    procedure DefinirDadosMsg; virtual;
    procedure DefinirEnvelopeSoap; virtual;
    procedure SalvarEnvio; virtual;
    procedure EnviarDados; virtual;
    function TratarResposta: Boolean; virtual;
    procedure SalvarResposta; virtual;
    procedure FinalizarServico; virtual;

    function GerarMsgLog: String; virtual;
    function GerarMsgErro(E: Exception): String; virtual;
    function GerarCabecalhoSoap: String; virtual;
    function GerarVersaoDadosSoap: String; virtual;
    function GerarUFSoap: String; virtual;
    function GerarPrefixoArquivo: String; virtual;
  public
    constructor Create(AOwner: TACBrDFe);

    function Executar: Boolean; virtual;

    property SoapVersion: String read FSoapVersion;
    property SoapEnvelopeAtributtes: String
      read FSoapEnvelopeAtributtes;
    property HeaderElement: String read FHeaderElement;
    property BodyElement: String read FBodyElement;

    property Servico: String read FServico;
    property SoapAction: String read FSoapAction;
    property URL: String read FURL;
    property CabMsg: String read FCabMsg;
    property DadosMsg: String read FDadosMsg;
    property EnvelopeSoap: String read FEnvelopeSoap;
    property RetornoWS: String read FRetornoWS;
    property RetWS: String read FRetWS;
    property Msg: String read FMsg;
    property ArqEnv: String read FArqEnv;
    property ArqResp: String read FArqResp;
  end;

implementation

uses
  ssl_openssl,
  ACBrDFeUtil, ACBrUtil, StrUtils, pcnGerador;

{ TDFeWebService }

constructor TDFeWebService.Create(AOwner: TACBrDFe);
begin
  FDFeOwner := AOwner;
  FConfiguracoes := AOwner.Configuracoes;

  FSoapVersion := 'soap12';
  FHeaderElement := 'nfeCabecMsg';
  FBodyElement := 'nfeDadosMsg';
  FSoapEnvelopeAtributtes :=
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
    'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
    'xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"';

  FCabMsg := '';
  FDadosMsg := '';
  FRetornoWS := '';
  FRetWS := '';
  FMsg := '';
  FURL := '';
  FArqEnv := '';
  FArqResp := '';
  FServico := '';
  FSoapAction := '';
end;

procedure TDFeWebService.ConfiguraHTTP(HTTP: THTTPSend; Action: String);
begin
  if FileExists(FConfiguracoes.Certificados.ArquivoPFX) then
    HTTP.Sock.SSL.PFXfile := FConfiguracoes.Certificados.ArquivoPFX
  else
    HTTP.Sock.SSL.PFX := FConfiguracoes.Certificados.DadosPFX;

  HTTP.Sock.SSL.KeyPassword := FConfiguracoes.Certificados.Senha;

  HTTP.ProxyHost := FConfiguracoes.WebServices.ProxyHost;
  HTTP.ProxyPort := FConfiguracoes.WebServices.ProxyPort;
  HTTP.ProxyUser := FConfiguracoes.WebServices.ProxyUser;
  HTTP.ProxyPass := FConfiguracoes.WebServices.ProxyPass;

  if (pos('SCERECEPCAORFB', UpperCase(FURL)) <= 0) and
    (pos('SCECONSULTARFB', UpperCase(FURL)) <= 0) then
    HTTP.MimeType := 'application/soap+xml; charset=utf-8'
  else
    HTTP.MimeType := 'text/xml; charset=utf-8';

  HTTP.UserAgent := '';
  HTTP.Protocol := '1.1';
  HTTP.AddPortNumberToHost := False;
  HTTP.Headers.Add(Action);
end;

{$IFDEF SoapHTTP}
procedure TWebServicesBase.ConfiguraReqResp(ReqResp: THTTPReqResp);
begin
  if FConfiguracoes.WebServices.ProxyHost <> '' then
  begin
    ReqResp.Proxy := FConfiguracoes.WebServices.ProxyHost + ':' +
      FConfiguracoes.WebServices.ProxyPort;
    ReqResp.UserName := FConfiguracoes.WebServices.ProxyUser;
    ReqResp.Password := FConfiguracoes.WebServices.ProxyPass;
  end;
  ReqResp.OnBeforePost := OnBeforePost;
end;

procedure TWebServicesBase.OnBeforePost(const HTTPReqResp: THTTPReqResp; Data: Pointer);
var
  Cert: ICertificate2;
  CertContext: ICertContext;
  PCertContext: Pointer;
  ContentHeader: String;
begin
  Cert := FConfiguracoes.Certificados.GetCertificado;
  CertContext := Cert as ICertContext;
  CertContext.Get_CertContext(integer(PCertContext));

  if not InternetSetOption(Data, INTERNET_OPTION_CLIENT_CERT_CONTEXT,
    PCertContext, SizeOf(CERT_CONTEXT)) then
    GerarException('OnBeforePost: ' + IntToStr(GetLastError));

  if trim(FConfiguracoes.WebServices.ProxyUser) <> '' then
    if not InternetSetOption(Data, INTERNET_OPTION_PROXY_USERNAME,
      PChar(FConfiguracoes.WebServices.ProxyUser),
      Length(FConfiguracoes.WebServices.ProxyUser)) then
      GerarException('OnBeforePost: ' + IntToStr(GetLastError));

  if trim(FConfiguracoes.WebServices.ProxyPass) <> '' then
    if not InternetSetOption(Data, INTERNET_OPTION_PROXY_PASSWORD,
      PChar(FConfiguracoes.WebServices.ProxyPass),
      Length(FConfiguracoes.WebServices.ProxyPass)) then
      GerarException('OnBeforePost: ' + IntToStr(GetLastError));

  if (pos('SCERECEPCAORFB', UpperCase(FURL)) <= 0) and
    (pos('SCECONSULTARFB', UpperCase(FURL)) <= 0) then
  begin
    ContentHeader := Format(ContentTypeTemplate,
      ['application/soap+xml; charset=utf-8']);
    HttpAddRequestHeaders(Data, PChar(ContentHeader),
      Length(ContentHeader), HTTP_ADDREQ_FLAG_REPLACE);
  end;

  HTTPReqResp.CheckContentType;
end;

{$ELSE}

procedure TDFeWebService.ConfiguraReqResp(ReqResp: TACBrHTTPReqResp);
begin
  if FConfiguracoes.WebServices.ProxyHost <> '' then
  begin
    ReqResp.ProxyHost := FConfiguracoes.WebServices.ProxyHost;
    ReqResp.ProxyPort := FConfiguracoes.WebServices.ProxyPort;
    ReqResp.ProxyUser := FConfiguracoes.WebServices.ProxyUser;
    ReqResp.ProxyPass := FConfiguracoes.WebServices.ProxyPass;
  end;

  ReqResp.SetCertificate(FConfiguracoes.Certificados.NumeroSerie);

  if (pos('SCERECEPCAORFB', UpperCase(FURL)) <= 0) and
    (pos('SCECONSULTARFB', UpperCase(FURL)) <= 0) then
    ReqResp.MimeType := 'application/soap+xml'
  else
    ReqResp.MimeType := 'text/xml';
end;

{$ENDIF}

function TDFeWebService.Executar: Boolean;
var
  ErroMsg: String;
begin
  { Sobrescrever apenas se realmente necess�rio }

  InicializarServico;
  try
    DefinirDadosMsg;
    DefinirEnvelopeSoap;
    SalvarEnvio;

    try
      EnviarDados;
      Result := TratarResposta;
      FazerLog(GerarMsgLog, True);
      SalvarResposta;
    except
      on E: Exception do
      begin
        Result := False;
        ErroMsg := GerarMsgErro(E);
        GerarException(ErroMsg);
      end;
    end;
  finally
    FinalizarServico;
  end;
end;

procedure TDFeWebService.InicializarServico;
begin
  { Sobrescrever apenas se necess�rio }

  DefinirURL;
  if URL = '' then
    GerarException('URL n�o definida para: ' + ClassName);

  DefinirServicoEAction;
  if Servico = '' then
    GerarException('Servico n�o definido para: ' + ClassName);

  if SoapAction = '' then
    GerarException('SoapAction n�o definido para: ' + ClassName);
end;

procedure TDFeWebService.DefinirServicoEAction;
begin
  { sobrescrever, OBRIGATORIAMENTE }

  FServico := '';
  FSoapAction := '';

  GerarException('DefinirServicoEAction n�o implementado para: ' + ClassName);
end;

procedure TDFeWebService.DefinirURL;
begin
  { sobrescrever OBRIGATORIAMENTE.
    Voc� tamb�m pode mudar apenas o valor de "FLayoutServico" na classe
    filha e chamar: Inherited;     }

  GerarException('DefinirURL n�o implementado para: ' + ClassName);
end;


procedure TDFeWebService.DefinirDadosMsg;
begin
  { sobrescrever, OBRIGATORIAMENTE }

  FDadosMsg := '';

  GerarException('DefinirDadosMsg n�o implementado para: ' + ClassName);
end;


procedure TDFeWebService.DefinirEnvelopeSoap;
var
  Texto: String;
begin
  { Sobrescrever apenas se necess�rio }

  Texto := '<' + ENCODING_UTF8 + '>';    // Envelop Final DEVE SEMPRE estar em UTF8...
  Texto := Texto + '<' + FSoapVersion + ':Envelope ' + FSoapEnvelopeAtributtes + '>';
  Texto := Texto + '<' + FSoapVersion + ':Header>';
  Texto := Texto + '<' + FHeaderElement + ' xmlns="' + Servico + '">';
  Texto := Texto + GerarCabecalhoSoap;
  Texto := Texto + '</' + FHeaderElement + '>';
  Texto := Texto + '</' + FSoapVersion + ':Header>';
  Texto := Texto + '<' + FSoapVersion + ':Body>';
  Texto := Texto + '<' + FBodyElement + ' xmlns="' + Servico + '">';
  Texto := Texto + DadosMsg;
  Texto := Texto + '</' + FBodyElement + '>';
  Texto := Texto + '</' + FSoapVersion + ':Body>';
  Texto := Texto + '</' + FSoapVersion + ':Envelope>';

  FEnvelopeSoap := Texto;
end;

function TDFeWebService.GerarUFSoap: String;
begin
  Result := '<cUF>' + IntToStr(FConfiguracoes.WebServices.UFCodigo) + '</cUF>';
end;

function TDFeWebService.GerarVersaoDadosSoap: String;
begin
  { sobrescrever, OBRIGATORIAMENTE }

  GerarException('GerarVersaoDadosSoap n�o implementado para: ' + ClassName);
end;

procedure TDFeWebService.EnviarDados;
var
  {$IFDEF ACBrNFeOpenSSL}
  HTTP: THTTPSend;
  OK: Boolean;
  {$ELSE}
  Stream: TMemoryStream;
   {$IFDEF SoapHTTP}
  ReqResp: THTTPReqResp;
   {$ELSE}
  ReqResp: TACBrHTTPReqResp;
   {$ENDIF}
  {$ENDIF}
begin
  { Sobrescrever apenas se necess�rio }

  FRetWS := '';
  FRetornoWS := '';

  {$IFDEF ACBrNFeOpenSSL}
  HTTP := THTTPSend.Create;
  {$ELSE}
   {$IFDEF SoapHTTP}
  ReqResp := THTTPReqResp.Create(nil);
  ReqResp.UseUTF8InHeader := True;
   {$ELSE}
  ReqResp := TACBrHTTPReqResp.Create;
   {$ENDIF}
  ConfiguraReqResp(ReqResp);
  ReqResp.URL := URL;
  ReqResp.SoapAction := SoapAction;
  {$ENDIF}
  { Verifica se precisa converter o Envelope para UTF8 antes de ser enviado.
     Entretanto o Envelope pode j� ter sido convertido antes, como por exemplo,
     para assinatura.
     Se o XML est� assinado, n�o deve modificar o conte�do }

  if not DFeUtil.XMLisSigned(FEnvelopeSoap) then
    FEnvelopeSoap := DFeUtil.ConverteXMLtoUTF8(FEnvelopeSoap);

  try
    {$IFDEF ACBrNFeOpenSSL}
    ConfiguraHTTP(HTTP, 'SOAPAction: "' + SoapAction + '"');
    // DEBUG //
    //HTTP.Document.SaveToFile( 'c:\temp\HttpSend.xml' );
    HTTP.Document.WriteBuffer(FEnvelopeSoap[1], Length(FEnvelopeSoap));
    OK := HTTP.HTTPMethod('POST', URL);
    OK := OK and (HTTP.ResultCode = 200);
    if not OK then
      GerarException('Cod.Erro HTTP: ' + IntToStr(HTTP.ResultCode) +
        ' ' + HTTP.ResultString);

    // Lendo a resposta //
    HTTP.Document.Position := 0;
    SetLength(FRetornoWS, HTTP.Document.Size);
    HTTP.Document.ReadBuffer(FRetornoWS[1], HTTP.Document.Size);
    // DEBUG //
    HTTP.Document.SaveToFile('c:\temp\ReqResp.xml');
    {$ELSE}
    Stream := TMemoryStream.Create;
    try
      ReqResp.Execute(FEnvelopeSoap, Stream);  // Dispara exceptions no caso de erro
      SetLength(FRetornoWS, Stream.Size);
      Stream.ReadBuffer(FRetornoWS[1], Stream.Size);
      // DEBUG //
      Stream.SaveToFile('c:\temp\ReqResp.xml');
    finally
      Stream.Free;
    end;
    {$ENDIF}
    { Resposta sempre � UTF8, ParseTXT chamar� DecodetoString, que converter�
      de UTF8 para o formato nativo de  String usada pela IDE }
    FRetornoWS := ParseText(FRetornoWS, True, True);
  finally
    {$IFDEF ACBrNFeOpenSSL}
    HTTP.Free;
    {$ELSE}
    ReqResp.Free;
    {$ENDIF}
  end;
end;


function TDFeWebService.GerarPrefixoArquivo: String;
begin
  Result := FormatDateTime('yyyymmddhhnnss', Now);
end;

procedure TDFeWebService.SalvarEnvio;
var
  Prefixo, ArqEnv: String;
begin
  { Sobrescrever apenas se necess�rio }

  if FArqEnv = '' then
    exit;

  Prefixo := GerarPrefixoArquivo;

  if FConfiguracoes.Geral.Salvar then
  begin
    ArqEnv := Prefixo + '-' + FArqEnv + '.xml';
    FDFeOwner.Gravar(ArqEnv, FDadosMsg);
  end;

  if FConfiguracoes.WebServices.Salvar then
  begin
    ArqEnv := Prefixo + '-' + FArqEnv + '-soap.xml';
    FDFeOwner.Gravar(ArqEnv, FEnvelopeSoap);
  end;
end;

procedure TDFeWebService.SalvarResposta;
var
  Prefixo, ArqResp: String;
begin
  { Sobrescrever apenas se necess�rio }

  if FArqResp = '' then
    exit;

  Prefixo := GerarPrefixoArquivo;

  if FConfiguracoes.Geral.Salvar then
  begin
    ArqResp := Prefixo + '-' + FArqResp + '.xml';
    FDFeOwner.Gravar(ArqResp, FRetWS);
  end;

  if FConfiguracoes.WebServices.Salvar then
  begin
    ArqResp := Prefixo + '-' + FArqResp + '-soap.xml';
    FDFeOwner.Gravar(ArqResp, FRetornoWS);
  end;
end;

function TDFeWebService.GerarMsgLog: String;
begin
  { sobrescrever, se quiser Logar }

  Result := '';
end;

function TDFeWebService.TratarResposta: Boolean;
begin
  { sobrescrever, OBRIGATORIAMENTE }

  Result := False;
end;

procedure TDFeWebService.FazerLog(Msg: AnsiString; Exibir: Boolean);
var
  Tratado: Boolean;
begin
  if (Msg <> '') then
  begin
    Tratado := False;
    if Assigned(FDFeOwner.OnGerarLog) then
      FDFeOwner.OnGerarLog(Msg, Tratado);

    if Tratado then
      exit;

    {$IFNDEF NOGUI}
    if Exibir and FConfiguracoes.WebServices.Visualizar then
      ShowMessage(Msg);
    {$ENDIF}
  end;
end;

procedure TDFeWebService.GerarException(Msg: String);
begin
  FazerLog('ERRO: ' + Msg, False);
  raise EACBrDFeException.Create(Msg);
end;

function TDFeWebService.GerarMsgErro(E: Exception): String;
begin
  { Sobrescrever com mensagem adicional, se desejar }

  Result := E.Message;
end;

function TDFeWebService.GerarCabecalhoSoap: String;
begin
  { Sobrescrever apenas se necess�rio }

  Result := GerarUFSoap + GerarVersaoDadosSoap;

end;

procedure TDFeWebService.FinalizarServico;
begin
  { Sobrescrever apenas se necess�rio }

  DFeUtil.ConfAmbiente;
end;

end.
(*
// TODO: VERIFICAR:

CURL_WSDL = 'http://www.portalfiscal.inf.br/nfe/wsdl/';


function TWebServicesBase.EhAutorizacao: Boolean;
begin
  Result := False;
  case FConfiguracoes.Geral.ModeloDF of
    moNFe:
      if (FConfiguracoes.Geral.VersaoDF = ve310) then
        Result := True;
    moNFCe:
      if (FConfiguracoes.Geral.VersaoDF = ve310) and not
         (FConfiguracoes.WebServices.UFCodigo in [13])  then // AM
        Result := True;
  end;
end;

function TWebServicesBase.GerarSoapDEPC: String;
var
  Texto: String;
begin
  Texto := '<'+ENCODING_UTF8+'>';
  Texto := Texto + '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
                                  'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' +
                                  'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">';
  Texto := Texto + '<soap:Header>';
  Texto := Texto +  '<sceCabecMsg xmlns="' + Servico + '">';
  Texto := Texto +    GerarVersaoDadosSoap;
  Texto := Texto +  '</sceCabecMsg>';
  Texto := Texto + '</soap:Header>';
  Texto := Texto + '<soap:Body>';
  Texto := Texto +  '<sceDadosMsg xmlns="' + Servico +'">';
  Texto := Texto +    FDadosMsg;
  Texto := Texto +  '</sceDadosMsg>';
  Texto := Texto + '</soap:Body>';
  Texto := Texto + '</soap:Envelope>';

  Result := Texto;
end;



// TODO: Verificar onde fica...


property Status: TStatusACBrNFe   read FStatus;
property Layout: TLayOut          read FLayout;


procedure TWebServicesBase.AssinarXML(AXML: String; MsgErro: String);
begin
   if not NotaUtil.Assinar( AXML,
                            FConfiguracoes.Certificados.Certificado,
                            FConfiguracoes.Certificados.Senha,
                            FDadosMsg, FMsg )) then
   if not(NotaUtil.openAssinar( AXML,
                            FConfiguracoes.Certificados.GetCertificado,
                            FDadosMsg, FMsg )) then
     GerarException(MsgErro);
end;


procedure TWebServicesBase.InicializarServico;
begin
  { Sobrescrever apenas se necess�rio }

  TACBrNFe( FACBrNFe ).SetStatus( FStatus );
end;

procedure TWebServicesBase.DefinirURL;
begin
  { sobrescrever apenas se necess�rio.
    Voc� tamb�m pode mudar apenas o valor de "FLayoutServico" na classe
    filha e chamar: Inherited;     }

  FURL := NotaUtil.GetURL( FConfiguracoes.WebServices.UFCodigo,
                           FConfiguracoes.WebServices.AmbienteCodigo,
                           FConfiguracoes.Geral.FormaEmissaoCodigo,
                           Layout,
                           FConfiguracoes.Geral.ModeloDF,
                           FConfiguracoes.Geral.VersaoDF );
end;


function TWebServicesBase.GerarVersaoDadosSoap: String;
begin
  { Sobrescrever apenas se necess�rio }

  Result := '<versaoDados>' + GetVersaoNFe(FConfiguracoes.Geral.ModeloDF,
                                           FConfiguracoes.Geral.VersaoDF,
                                           Layout) +
            '</versaoDados>';
end;

procedure TWebServicesBase.FinalizarServico;
begin
  { Sobrescrever apenas se necess�rio }

  TACBrNFe( FACBrNFe ).SetStatus( stIdle );
end;

*)
