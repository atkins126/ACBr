{******************************************************************************}
{ Projeto: Componente ACBrNFe                                                  }
{  Biblioteca multiplataforma de componentes Delphi para emiss�o de Nota Fiscal}
{ eletr�nica - NFe - http://www.nfe.fazenda.gov.br                          }
{                                                                              }
{ Direitos Autorais Reservados (c) 2008 Wemerson Souto                         }
{                                       Daniel Simoes de Almeida               }
{                                       Andr� Ferreira de Moraes               }
{                                                                              }
{ Colaboradores nesse arquivo:                                                 }
{                                                                              }
{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do Projeto ACBr     }
{ Componentes localizado em http://www.sourceforge.net/projects/acbr           }
{                                                                              }
{                                                                              }
{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }
{                                                                              }
{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Daniel Sim�es de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{              Pra�a Anita Costa, 34 - Tatu� - SP - 18270-410                  }
{                                                                              }
{******************************************************************************}

{$I ACBr.inc}

unit ACBrDFeUtil;

interface

uses
  {$IFNDEF NOGUI} Forms, {$ENDIF}
  Classes, StrUtils, SysUtils;

type
  EACBrDFeException = class(Exception);

  { DFeUtil }

  DFeUtil = class
   private
   protected

   public
     class function FormatarNumeroDocumentoFiscal(AValue : String ): String;
     class function FormatarNumeroDocumentoFiscalNFSe(AValue: String): String;
     class function FormatarChaveAcesso(AValue : String ): String;
     class function ValidaUFCidade(const UF, Cidade: Integer): Boolean; overload;
     class procedure ValidaUFCidade(const UF, Cidade: Integer; const AMensagem: string); overload;
     class function ValidaDIDSI(AValue: string): Boolean;
     class function ValidaDIRE(AValue: string): Boolean;
     class function ValidaRE(AValue: string): Boolean;
     class function ValidaDrawback(AValue: string): Boolean;
     class function ValidaSUFRAMA(AValue: string): Boolean;
     class function ValidaRECOPI(AValue: string): Boolean;
     class function ValidaNVE(AValue: string): Boolean;

     class function ConverteXMLtoUTF8(const AXML: String): String;
     class function XmlEstaAssinado(const AXML: String): Boolean;
     class function XmlEhUTF8(const AXML: String): Boolean;
     class function ExtraiURI(const AXML: String): String;
   end;

implementation

uses
 Variants, DateUtils, ACBrUtil, ACBrConsts, pcnGerador;


class function DFeUtil.FormatarNumeroDocumentoFiscal(AValue: String): String;
begin
  AValue := Poem_Zeros(AValue, 9);
  Result := copy(AValue,1,3) + '.' + copy(AValue,4,3)+ '.'+
            copy(AValue,7,3);
end;

class function DFeUtil.FormatarNumeroDocumentoFiscalNFSe(AValue: String): String;
begin
  AValue := Poem_Zeros(AValue, 15);
  Result := copy(AValue,1,4) + '.' + copy(AValue,5,12);
end;

class function DFeUtil.ValidaUFCidade(const UF, Cidade: Integer): Boolean;
begin
  Result := (Copy(IntToStr(UF), 1, 2) = Copy(IntToStr(Cidade), 1, 2));
end;

class procedure DFeUtil.ValidaUFCidade(const UF, Cidade: Integer;
  const AMensagem: string);
begin
  if not (ValidaUFCidade(UF, Cidade)) then
    raise EACBrDFeException.Create(AMensagem);
end;

class function DFeUtil.FormatarChaveAcesso(AValue: String): String;
begin
  AValue := OnlyNumber(AValue);
  Result := copy(AValue,1,4)  + ' ' + copy(AValue,5,4)  + ' ' +
            copy(AValue,9,4)  + ' ' + copy(AValue,13,4) + ' ' +
            copy(AValue,17,4) + ' ' + copy(AValue,21,4) + ' ' +
            copy(AValue,25,4) + ' ' + copy(AValue,29,4) + ' ' +
            copy(AValue,33,4) + ' ' + copy(AValue,37,4) + ' ' +
            copy(AValue,41,4) ;
end;

class function DFeUtil.ValidaDIDSI(AValue: string): Boolean;
var
 ano: Integer;
 sValue: String;
begin
  // AValue = TAANNNNNNND
  // Onde: T Identifica o tipo de documento ( 2 = DI e 4 = DSI )
  //       AA Ano corrente da gera��o do documento
  //       NNNNNNN N�mero sequencial dentro do Ano ( 7 ou 8 d�gitos )
  //       D D�gito Verificador, M�dulo 11, Pesos de 2 a 9
  AValue := OnlyNumber(AValue);
  ano := StrToInt(Copy(IntToStr(YearOf(Date)), 3, 2));

 if (length(AValue) < 11) or (length(AValue) > 12) then
   Result := False
 else if (copy(Avalue, 1, 1) <> '2') and (copy(Avalue, 1, 1) <> '4') then
   Result := False
 else if not ((StrToInt(copy(Avalue, 2, 2)) >= ano -1) and (StrToInt(copy(Avalue, 2, 2)) <= ano +1)) then
   Result := False
 else
 begin
   sValue := copy(AValue, 1, length(AValue)- 1);
   Result := copy(AValue, length(AValue), 1) = Modulo11(sValue);
 end;
end;

class function DFeUtil.ValidaDIRE(AValue: string): Boolean;
var
 ano: Integer;
begin
 // AValue = AANNNNNNNNNN
 // Onde: AA Ano corrente da gera��o do documento
 //       NNNNNNNNNN N�mero sequencial dentro do Ano ( 10 d�gitos )
 AValue := OnlyNumber(AValue);
 ano := StrToInt(Copy(IntToStr(YearOf(Date)), 3, 2));

 if length(AValue) <> 12 then
   Result := False
 else
   Result := (StrToInt(copy(Avalue, 1, 2)) >= ano -1) and (StrToInt(copy(Avalue, 1, 2)) <= ano +1);
end;

class function DFeUtil.ValidaRE(AValue: string): Boolean;
var
 ano: Integer;
begin
 // AValue = AANNNNNNNSSS
 // Onde: AA Ano corrente da gera��o do documento
 //       NNNNNNN N�mero sequencial dentro do Ano ( 7 d�gitos )
 //       SSS Serie do RE (001, 002, ...)
 AValue := OnlyNumber(AValue);
 ano := StrToInt(Copy(IntToStr(YearOf(Date)), 3, 2));

 if length(AValue) <> 12 then
   Result := False
 else if not ((StrToInt(copy(Avalue, 2, 2)) >= ano -1) and (StrToInt(copy(Avalue, 2, 2)) <= ano +1)) then
   Result := False
 else
   Result := (StrToInt(copy(Avalue, 10, 3)) >= 1) and (StrToInt(copy(Avalue, 10, 3)) <= 999);
end;

class function DFeUtil.ValidaDrawback(AValue: string): Boolean;
var
 ano: Integer;
begin
 // AValue = AAAANNNNNND
 // Onde: AAAA Ano corrente do registro
 //       NNNNNN N�mero sequencial dentro do Ano ( 6 d�gitos )
 //       D D�gito Verificador, M�dulo 11, Pesos de 2 a 9
 AValue := OnlyNumber(AValue);
 ano := StrToInt(Copy(IntToStr(YearOf(Date)), 3, 2));
 if length(AValue) = 11 then
   AValue := copy(AValue, 3, 9);

 if length(AValue) <> 9 then
   Result := False
 else if not ((StrToInt(copy(Avalue, 1, 2)) >= ano -1) and (StrToInt(copy(Avalue, 1, 2)) <= ano +1)) then
   Result := False
 else
   Result := copy(AValue, 9, 1) = Modulo11(copy(AValue, 1, 8));
end;

class function DFeUtil.ValidaSUFRAMA(AValue: string): Boolean;
var
 SS, LL: Integer;
begin
 // AValue = SSNNNNLLD
 // Onde: SS C�digo do setor de atividade da empresa ( 01, 02, 10, 11, 20 e 60 )
 //       NNNN N�mero sequencial ( 4 d�gitos )
 //       LL C�digo da localidade da Unidade Administrativa da Suframa ( 01 = Manaus, 10 = Boa Vista e 30 = Porto Velho )
 //       D D�gito Verificador, M�dulo 11, Pesos de 2 a 9
 AValue := OnlyNumber(AValue);
 if length(AValue) < 9 then
   AValue := '0' + AValue;
 if length(AValue) <> 9 then
   Result := False
 else
  begin
   SS := StrToInt(copy(Avalue, 1, 2));
   LL := StrToInt(copy(Avalue, 7, 2));
   if not (SS in [01, 02, 10, 11, 20, 60]) then
     Result := False
   else if not (LL in [01, 10, 30]) then
          Result := False
        else
          Result := copy(AValue, 9, 1) = Modulo11(copy(AValue, 1, 8));
 end;
end;

class function DFeUtil.ValidaRECOPI(AValue: string): Boolean;
begin
 // AValue = aaaammddhhmmssffffDD
 // Onde: aaaammdd Ano/Mes/Dia da autoriza��o
 //       hhmmssffff Hora/Minuto/Segundo da autoriza��o com mais 4 digitos da fra��o de segundo
 //       DD D�gitos Verificadores, M�dulo 11, Pesos de 1 a 18 e de 1 a 19
 AValue := OnlyNumber(AValue);
 if length(AValue) <> 20 then
   Result := False
 else if copy(AValue, 19, 1) <> Modulo11(copy(AValue, 1, 18), 1, 18) then
        Result := False
      else Result := copy(AValue, 20, 1) = Modulo11(copy(AValue, 1, 19), 1, 19);
end;

class function DFeUtil.ValidaNVE(AValue: string): Boolean;
begin
 Result := True;
end;

class function DFeUtil.XmlEhUTF8(const AXML: String): Boolean;
begin
  Result := (pos('encoding="utf-8"', LowerCase(LeftStr(AXML,50))) > 0);
end ;

class function DFeUtil.ExtraiURI(const AXML: String): String;
var
  I, J: Integer;
begin
 //// Encontrando o URI ////
 I := PosEx('Id=', AXML, 6);
 if I = 0 then
   raise EACBrDFeException.Create('N�o encontrei inicio do URI: Id=');

 I := PosEx('"', AXML, I + 2);
 if I = 0 then
   raise EACBrDFeException.Create('N�o encontrei inicio do URI: aspas inicial');

 J := PosEx('"', AXML, I + 1);
 if J = 0 then
   raise EACBrDFeException.Create('N�o encontrei inicio do URI: aspas final');

 Result := copy(AXML, I + 1, J - I - 1);
end;

class function DFeUtil.XmlEstaAssinado(const AXML: String): Boolean;
begin
Result := (pos('<signature', lowercase(AXML)) > 0);
end;

class function DFeUtil.ConverteXMLtoUTF8(const AXML: String): String;
Var
  UTF8Str : String;
begin
  if not XmlEhUTF8(AXML) then   // J� foi convertido antes ?
  begin
    {$IFNDEF UNICODE}
     UTF8Str := UTF8Encode(AXML);
    {$ELSE}
     UTF8Str := AXML;
    {$ENDIF}

    Result := '<'+ENCODING_UTF8+'>' + UTF8Str;
  end
  else
     Result := AXML;
end ;


end.




(*

///  TODO: REMOVER ??


class function TrataString(const AValue: String): String;overload;
class function TrataString(const AValue: String; const ATamanho: Integer): String;overload;

class function DFeUtil.TrataString(const AValue: String;
  const ATamanho: Integer): String;
begin
  Result := TrataString(LeftStr(AValue, ATamanho));
end;

class function DFeUtil.TrataString(const AValue: String): String;
var
  A : Integer ;
begin
  Result := '' ;
  For A := 1 to length(AValue) do
  begin
    case Ord(AValue[A]) of
      60  : Result := Result + '&lt;';  //<
      62  : Result := Result + '&gt;';  //>
      38  : Result := Result + '&amp;'; //&
      34  : Result := Result + '&quot;';//"
      39  : Result := Result + '&#39;'; //'
      32  : begin          // Retira espa�os duplos
              if ( Ord(AValue[Pred(A)]) <> 32 ) then
                 Result := Result + ' ';
            end;
      193 : Result := Result + 'A';//�
      224 : Result := Result + 'a';//�
      226 : Result := Result + 'a';//�
      234 : Result := Result + 'e';//�
      244 : Result := Result + 'o';//�
      251 : Result := Result + 'u';//�
      227 : Result := Result + 'a';//�
      245 : Result := Result + 'o';//�
      225 : Result := Result + 'a';//�
      233 : Result := Result + 'e';//�
      237 : Result := Result + 'i';//�
      243 : Result := Result + 'o';//�
      250 : Result := Result + 'u';//�
      231 : Result := Result + 'c';//�
      252 : Result := Result + 'u';//�
      192 : Result := Result + 'A';//�
      194 : Result := Result + 'A';//�
      202 : Result := Result + 'E';//�
      212 : Result := Result + 'O';//�
      219 : Result := Result + 'U';//�
      195 : Result := Result + 'A';//�
      213 : Result := Result + 'O';//�
      201 : Result := Result + 'E';//�
      205 : Result := Result + 'I';//�
      211 : Result := Result + 'O';//�
      218 : Result := Result + 'U';//�
      199 : Result := Result + 'C';//�
      220 : Result := Result + 'U';//�
    else
      Result := Result + AValue[A];
    end;
  end;
  Result := Trim(Result);
end;

class function DFeUtil.CollateBr(Str: String): String;
var
   i, wTamanho: integer;
   wChar, wResultado: Char;
begin
   result   := '';
   wtamanho := Length(Str);
   i        := 1;
   while (i <= wtamanho) do
   begin
      wChar := Str[i];
      case wChar of
         '�', '�', '�', '�', '�', '�',
         '�', '�', '�', '�', '�', '�': wResultado := 'A';
         '�', '�', '�', '�',
         '�', '�', '�', '�': wResultado := 'E';
         '�', '�', '�', '�',
         '�', '�', '�', '�': wResultado := 'I';
         '�', '�', '�', '�', '�',
         '�', '�', '�', '�', '�': wResultado := 'O';
         '�', '�', '�', '�',
         '�', '�', '�', '�': wResultado := 'U';
         '�', '�': wResultado := 'C';
         '�', '�': wResultado := 'N';
         '�', '�', '�', 'Y': wResultado := 'Y';
      else
         wResultado := wChar;
      end;
      i      := i + 1;
      Result := Result + wResultado;
   end;
   Result := UpperCase(Result);
end;



class function DFeUtil.FormatarFone(AValue: String): String;
var
  lTemp: string;
begin
  AValue := LimpaNumero(AValue);

  if Length(AValue) = 0 then
     Result := AValue
  else
   begin
     AValue := IntToStr(StrToInt64Def(AValue, 0));
     Result := AValue;
     lTemp  := '';
   end;

  if NaoEstaVazio(AValue) then
  begin
    if copy(AValue, 1, 3) = '800' then
      Result := '0' + copy(AValue, 1, 3) + '-' + copy(AValue, 4, 3) + '-' + copy(AValue, 7, 4)
    else
    case length(AValue) of
       8: Result := '(  )' + copy(AValue, 1, 4) + '-' + copy(AValue, 5, 4);
       9: begin
            if copy(AValue, 1, 1) = '9' // Celulares do Municipio de S�o Paulo tem 9 Digitos e o primeiro � 9
              then Result := '(  )' + copy(AValue, 1, 5) + '-' + copy(AValue, 6, 4)
              else begin
               ltemp := '0' + copy(AValue, 1, 1);
               Result := '(' + lTemp + ')' + copy(AValue, 2, 4) + '-' + copy(AValue, 6, 4);
              end;
         end;
       12: begin // Exemplo: 551133220000
             ltemp := copy(AValue, 1, 4);
             Result := '(' + lTemp + ')' + copy(AValue, 5, 4) + '-' + copy(AValue, 9, 4);
         end;
       13: begin // Exemplo: 5511999220000
             ltemp := copy(AValue, 1, 4);
             Result := '(' + lTemp + ')' + copy(AValue, 5, 5) + '-' + copy(AValue, 10, 4);
         end;
       else
       begin
         AValue := Poem_Zeros(AValue, 12);
         if (copy(AValue, 1, 1) = '0') and (copy(AValue, 2, 1) = '0')
           then begin
             ltemp := copy(AValue, 3, 2);
             Result := '(' + lTemp + ')' + copy(AValue, 5, 4) + '-' + copy(AValue, 9, 4);
           end
           else begin
             ltemp := copy(AValue, 2, 2);
             Result := '(' + lTemp + ')' + copy(AValue, 4, 5) + '-' + copy(AValue, 9, 4);
           end;
       end;
    end;
  end;
end;





class function DFeUtil.UpperCase2(Str: String): String;
var
   i, wTamanho: integer;
   wChar, wResultado: Char;
begin
   result   := '';
   wtamanho := Length(Str);
   i        := 1;
   while (i <= wtamanho) do
   begin
      wChar := Str[i];
      case wChar of
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�','�': wResultado := '�';
         '�', '�': wResultado := '�';
         '�', '�': wResultado := '�';
         '�', '�', '�', 'Y': wResultado := 'Y';
      else
         wResultado := wChar;
      end;
      i      := i + 1;
      Result := Result + wResultado;
   end;
   Result := UpperCase(Result);
end;


class function DFeUtil.FormatDate(const AString: string): String;
var
  vTemp: TDateTime;
{$IFDEF VER140} //D6
{$ELSE}
  vFormatSettings : TFormatSettings;
{$ENDIF}
begin
  try
{$IFDEF VER140} //D6
    DateSeparator := '/';
    ShortDateFormat := 'dd/mm/yyyy';
{$ELSE}
    vFormatSettings.DateSeparator   := '-';
    vFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
//    vTemp := StrToDate(AString, FFormato);
{$ENDIF}
    vTemp := StrToDate(AString);
    if vTemp = 0 then
      Result := ''
    else
      Result := DateToStr(vTemp);
  except
    Result := '';
  end;
end;

class function DFeUtil.FormatDate(const AData: TDateTime): String;
var
  vTemp: String;
{$IFDEF VER140} //delphi6
{$ELSE}
  FFormato : TFormatSettings;
{$ENDIF}
begin
  try
{$IFDEF VER140} //delphi6
    DateSeparator := '/';
    ShortDateFormat := 'dd/mm/yyyy';
{$ELSE}
    FFormato.DateSeparator   := '-';
    FFormato.ShortDateFormat := 'yyyy-mm-dd';
{$ENDIF}
	vTemp := DateToStr(AData);
    if AData = 0 then
      Result := ''
    else
      Result := vTemp;
  except
    Result := '';
  end;
end;

class function DFeUtil.FormatDateTime(const AString: string): string;
var
  vTemp : TDateTime;
{$IFDEF VER140} //delphi6
{$ELSE}
vFormatSettings: TFormatSettings;
{$ENDIF}
begin
  try
{$IFDEF VER140} //delphi6
    DateSeparator   := '/';
    ShortDateFormat := 'dd/mm/yyyy';
    ShortTimeFormat := 'hh:nn:ss';
{$ELSE}
    vFormatSettings.DateSeparator   := '-';
    vFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
    //    vTemp := StrToDate(AString, FFormato);
{$ENDIF}
    vTemp := StrToDateTime(AString);
    if vTemp = 0 then
      Result := ''
    else
      Result := DateTimeToStr(vTemp);
  except
    Result := '';
  end;
end;

class function DFeUtil.FormatFloat(AValue: Extended;
  const AFormat: string): String;
{$IFDEF VER140} //D6
{$ELSE}
var
vFormatSettings: TFormatSettings;
{$ENDIF}
begin
{$IFDEF VER140} //D6
  DecimalSeparator  := ',';
  ThousandSeparator := '.';
  Result := SysUtils.FormatFloat(AFormat, AValue);
{$ELSE}
  vFormatSettings.DecimalSeparator  := ',';
  vFormatSettings.ThousandSeparator := '.';
  Result := SysUtils.FormatFloat(AFormat, AValue, vFormatSettings);
{$ENDIF}
end;

class function DFeUtil.StringToDate(const AString: string): TDateTime;
begin
  if (AString = '0') or (AString = '') then
     Result := 0
  else
     Result := StrToDate(AString);
end;

class function DFeUtil.StringToTime(const AString: string): TDateTime;
begin
  if (AString = '0') or (AString = '') then
     Result := 0
  else
     Result := StrToTime(AString);
end;


class function Modulo11(Valor: string; Peso: Integer = 2; Base: Integer = 9): String;

*)
