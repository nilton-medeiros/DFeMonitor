#include "hmg.ch"
#include "hbclass.ch"

// GED - Gerenciador Eletrônico de Documentos - via FTP

class TGED_FTP
   data hostFile init '' protected
   data remotePath init '' protected
   data remoteFile init '' protected
   data urlFile init '' protected
   data isUpload init false readonly
   data deletedStatus init false protected

   method new(host_file, remote_path, remote_file) constructor
   method upload()
   method delete()
   method getURL() inline ::urlFile

end class

method new(host_file, remote_path, remote_file) class TGED_FTP
   default remote_file := token(host_file, '\') // Igual a SubStr(host_file, Rat('\', host_file)+1)
   ::hostFile := host_file
   ::remotePath := remote_path
   ::remoteFile := remote_file
   ::urlFile := appFTP:urlFiles + ::remotePath + "/" + ::remoteFile
return self

method upload() class TGED_FTP
   local url, ftp, error := 'UPLOAD - Erro de FTP: '

   saveLog('Iniciando upload de arquivo: ' + ::hostFile)

   ::isUpload := false

   if hb_FileExists(::hostFile)
      url := TUrl():new(appFTP:url)
      ftp := TIPClientFTP():New(url)
      ftp:nConnTimeout := 20000
      ftp:bUsePasv := true
      ftp:oURL:cServer := appFTP:server
      ftp:oURL:cUserID := appFTP:user
      ftp:oURL:cPassword := appFTP:password
      if ftp:open(appFTP:url)
         url:cPath := 'public_html/' + ::remotePath
         ftp:cwd(url:cPath)
         if ftp:uploadFile(::hostFile, ::remoteFile)
            ::isUpload := true
            saveLog('Upload de arquivo concluído com sucesso')
         else
            saveLog({'Falha no upload de arquivo', 'host file: ' + ::hostFile, 'remote file: ' + ::remoteFile}, "Error")
         endif
         ftp:close()
      else
         if (ftp:socketCon == Nil)
            error += 'Conexão não iniciada'
         elseif (hb_inetErrorCode(ftp:socketCon) == 0)
            error += 'Resposta do servidor: ' + ftp:cReply
         else
            error += hb_inetErrorDesc(ftp:socketCon)
         endif
         saveLog({error, 'host file: ' + ::hostFile, 'remote file: ', ::remoteFile}, "Error")
      endif
   else
      saveLog({'Erro ao fazer upload! Arquivo inexistente: ' + ::hostFile}, "Error")
   endif

return ::isUpload

method delete() class TGED_FTP
   local url := TUrl():new(appData:ftp_url)
   local ftp := TIPClientFTP():new(url)
   local error := 'DELETE - Erro de FTP: '

   ::deletedStatus := false

   ftp:nConnTimeout := 20000
   ftp:bUsePasv := true
   ftp:oURL:cServer := appData:ftp_server
   ftp:oURL:cUserID := appData:ftp_userId
   ftp:oURL:cPassword := appData:ftp_password

   if ftp:open(appData:ftp_url)
      url:cPath := 'public_html/' + ::remotePath
      ftp:cwd(url:cPath)
      ::deletedStatus := ftp:dele(::remoteFile)
      ftp:close()
   else
      if (ftp:socketCon == Nil)
         error += 'Conexão não iniciada'
      elseif (hb_inetErrorCode(ftp:socketCon) == 0)
         error += 'Resposta do servidor: ' + ftp:cReply
      else
         error += hb_inetErrorDesc(ftp:socketCon)
      endif
      saveLog({error, 'remote file: ' + ::remoteFile}, "Error")
   endif

return ::deletedStatus
