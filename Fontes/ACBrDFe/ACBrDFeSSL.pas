{******************************************************************************}
{ Projeto: Componente ACBrNFe                                                  }
{  Biblioteca multiplataforma de componentes Delphi para emiss�o de Nota Fiscal}
{ eletr�nica - NFe - http://www.nfe.fazenda.gov.br                             }

{ Direitos Autorais Reservados (c) 2015 Daniel Simoes de Almeida               }
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

unit ACBrDFeSSL;

interface

uses
  Classes, SysUtils, ACBrDFeConfiguracoes;

type
  { TDFeSSLClass }

  TDFeSSLClass = class
  private
    FConfiguracoes: TConfiguracoes;

  protected
    property Configuracoes: TConfiguracoes read FConfiguracoes;

    function SignatureElement(const URI: String; AddX509Data: Boolean): String;
  public
    constructor Create(AConfiguracoes: TConfiguracoes);
    function Assinar(const ConteudoXML, docElement, infElement: String): String;
      virtual;
    function Enviar(const ConteudoXML: AnsiString; const URL: String;
      const SoapAction: String): AnsiString; virtual;
  end;

  { TDFeSSL }

  TDFeSSL = class
  private
    FDFeOwner: TComponent;
    FConfiguracoes: TConfiguracoes;
    FSSLClass: TDFeSSLClass;
    FSSLLib: TSSLLib;

    procedure SetSSLLib(ASSLLib: TSSLLib);
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Assinar(const ConteudoXML, docElement, infElement: String): String;
    function Enviar(var ConteudoXML: AnsiString; const URL: String;
      const SoapAction: String): AnsiString;
  end;


implementation

uses strutils, ACBrUtil, ACBrDFe, ACBrDFeUtil, ACBrDFeOpenSSL, ACBrDFeCapicom;

{ TDFeSSL }

constructor TDFeSSL.Create(AOwner: TComponent);
begin
  if not (AOwner is TACBrDFe) then
    raise EACBrDFeException.Create('Owner de TDFeSSL deve ser do tipo TACBrDFe');

  inherited Create;

  FDFeOwner := AOwner;
  FConfiguracoes := TACBrDFe(FDFeOwner).Configuracoes;
  FSSLClass := TDFeSSLClass.Create(FConfiguracoes);
  FSSLLib := libNone;
end;

destructor TDFeSSL.Destroy;
begin
  if Assigned(FSSLClass) then
    FreeAndNil(FSSLClass);

  inherited Destroy;
end;

function TDFeSSL.Assinar(const ConteudoXML, docElement, infElement: String): String;
begin
  SetSSLLib(FConfiguracoes.Geral.SSLLib);

  Result := FSSLClass.Assinar(ConteudoXML, docElement, infElement);
end;

function TDFeSSL.Enviar(var ConteudoXML: AnsiString; const URL: String;
  const SoapAction: String): AnsiString;
begin
  SetSSLLib(FConfiguracoes.Geral.SSLLib);

  Result := FSSLClass.Enviar(ConteudoXML, URL, SoapAction);
end;

procedure TDFeSSL.SetSSLLib(ASSLLib: TSSLLib);
begin
  if ASSLLib = FSSLLib then
    exit;

  if Assigned(FSSLClass) then
    FreeAndNil(FSSLClass);

  case ASSLLib of
    libCapicom: FSSLClass := TDFeCapicom.Create(FConfiguracoes);
    libOpenSSL: FSSLClass := TDFeOpenSSL.Create(FConfiguracoes);
    else
      FSSLClass := TDFeSSLClass.Create(FConfiguracoes);
  end;

  FSSLLib := ASSLLib;
end;

{ TDFeSSLClass }

constructor TDFeSSLClass.Create(AConfiguracoes: TConfiguracoes);
begin
  FConfiguracoes := AConfiguracoes;
end;

function TDFeSSLClass.Assinar(const ConteudoXML, docElement, infElement: String): String;
begin
  Result := '';
  raise EACBrDFeException.Create(ClassName + '.Assinar, n�o implementado');
end;

function TDFeSSLClass.Enviar(const ConteudoXML: AnsiString; const URL: String;
  const SoapAction: String): AnsiString;
begin
  Result := '';
  raise EACBrDFeException.Create(ClassName + '.Enviar n�o implementado');
end;

function TDFeSSLClass.SignatureElement(const URI: String; AddX509Data: Boolean): String;
begin
  {(*}
  Result :=
  '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' +
    '<SignedInfo>' +
      '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
      '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />' +
      '<Reference URI="#' + URI + '">' +
        '<Transforms>' +
          '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
          '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
        '</Transforms>' +
        '<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />' +
        '<DigestValue></DigestValue>' +
      '</Reference>' +
    '</SignedInfo>' +
    '<SignatureValue></SignatureValue>' +
    IfThen(AddX509Data,
    '<KeyInfo>' +
      '<X509Data>' +
        '<X509Certificate></X509Certificate>' +
      '</X509Data>' +
    '</KeyInfo>',
    '<KeyInfo></KeyInfo>') +
  '</Signature>';
  {*)}
end;

end.

(*

// TODO: Verificar chamadas de assintura...

cDTD     = '<!DOCTYPE test [<!ATTLIST infNFe Id ID #IMPLIED>]>' ;
 cDTDCanc = '<!DOCTYPE test [<!ATTLIST infCanc Id ID #IMPLIED>]>' ;
 cDTDInut = '<!DOCTYPE test [<!ATTLIST infInut Id ID #IMPLIED>]>' ;
 cDTDDpec = '<!DOCTYPE test [<!ATTLIST infDPEC Id ID #IMPLIED>]>' ;
 cDTDCCe  = '<!DOCTYPE test [<!ATTLIST infEvento Id ID #IMPLIED>]>' ;
 cDTDEven = '<!DOCTYPE test [<!ATTLIST infEvento Id ID #IMPLIED>]>' ;

 </NFe>
 </cancNFe>
 </inutNFe>
 </envDPEC>
 </evento>

 *)
