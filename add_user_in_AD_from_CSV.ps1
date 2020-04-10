﻿ <#
 Description
 --FROM 1C
 ТекстовыйДокИзФайла.ДобавитьСтроку(Строка(Стр.ДатаПриема)+","+Стр.Фамилия+","+Стр.Имя+","+Стр.Отчество+","+Стр.Город+","+Стр.Адрес+","+Стр.Индекс+","+Стр.Отдел+","+Стр.Должность+","+Стр.Организация+","+Стр.Руководитель+","+Стр.РабочийНомер+","+Стр.МобильныйТелефон+","+Стр.ВнутренийНомер+","+СтрокаПИБ+","); 

 Example:

 05.11.2019 0:00:00,
 Иванов,
 Иван,
 Иванович,
 Барнаул,
 Ивановская ул/999//,
 123456,
 1.3.1.1. Центр тестирования качества обслуживания,
 Инженер 3 категории,
 ООО "КОМПАНИЯ",
 Петров Петр Петрович,
 ,
 8 123 456 7899,
 1-111,
 ,
 #>

$Header =   'DateAndTime',`
            'SN',`
            'GivenName',`
            'Patronymic',`
            'City',`
            'StreetAddress',`
            'Postcode',`
            'Department',`
            'Title',`
            'Company', `
            'Manager',`
            'HomePhone',`
            'MobilePhone',`
            'OfficePhone',`
            'empty-2'


#FILES
$CSVfile = "file_name.csv"
$log = "file_log.txt"

#MAIL
$IPMailServer="FQDN_server"
$SenderEmail="address@domain"
$RecipientEmail="address@domain"
$username = “domain\user”
$secpasswd = ConvertTo-SecureString 'Sclu$te4' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
$SubjectMail= "Login and password new employee"
$encoding = [System.Text.Encoding]::UTF8


#MAILBOX
$Database = "database_name" 
$ConnectionUri="http://FQDN_server/powershell"
$ConfigurationName= "Microsoft.Exchange"

function setPassword {
    $pass = ""
    $rnd = New-Object Random
    $chr = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*_-=+\/?:;<>|{}()[]"
    $k = 0; while ($k -ne 10) {$pass += $chr[$rnd.Next(0, [int]($chr.length))]; $k++}
    $pass = ConvertTo-SecureString -AsPlainText "$pass" -force  
    
    if ($pass -like "System.Security.SecureString"){
        Write-Host -ForegroundColor Green "Password create correctly!"
        return $pass
    }
    else {
        Write-Host -ForegroundColor Red "Password doesn't create correctly!"
        return
    }
    
} 

function Translit {param([string]$inString)
    $Translit = @{ 
    [char]'а' = "a"
    [char]'А' = "A"
    [char]'б' = "b"
    [char]'Б' = "B"
    [char]'в' = "v"
    [char]'В' = "V"
    [char]'г' = "g"
    [char]'Г' = "G"
    [char]'д' = "d"
    [char]'Д' = "D"
    [char]'е' = "e"
    [char]'Е' = "E"
    [char]'ё' = "yo"
    [char]'Ё' = "Yo"
    [char]'ж' = "zh"
    [char]'Ж' = "Zh"
    [char]'з' = "z"
    [char]'З' = "Z"
    [char]'и' = "i"
    [char]'И' = "I"
    [char]'й' = "j"
    [char]'Й' = "J"
    [char]'к' = "k"
    [char]'К' = "K"
    [char]'л' = "l"
    [char]'Л' = "L"
    [char]'м' = "m"
    [char]'М' = "M"
    [char]'н' = "n"
    [char]'Н' = "N"
    [char]'о' = "o"
    [char]'О' = "O"
    [char]'п' = "p"
    [char]'П' = "P"
    [char]'р' = "r"
    [char]'Р' = "R"
    [char]'с' = "s"
    [char]'С' = "S"
    [char]'т' = "t"
    [char]'Т' = "T"
    [char]'у' = "u"
    [char]'У' = "U"
    [char]'ф' = "f"
    [char]'Ф' = "F"
    [char]'х' = "h"
    [char]'Х' = "H"
    [char]'ц' = "c"
    [char]'Ц' = "C"
    [char]'ч' = "ch"
    [char]'Ч' = "Ch"
    [char]'ш' = "sh"
    [char]'Ш' = "Sh"
    [char]'щ' = "sch"
    [char]'Щ' = "Sch"
    [char]'ъ' = ""
    [char]'Ъ' = ""
    [char]'ы' = "y"
    [char]'Ы' = "Y"
    [char]'ь' = ""
    [char]'Ь' = ""
    [char]'э' = "e"
    [char]'Э' = "E"
    [char]'ю' = "yu"
    [char]'Ю' = "Yu"
    [char]'я' = "ya"
    [char]'Я' = "Ya"
    }
    $outCHR=""
    foreach ($CHR in $inCHR = $inString.ToCharArray())
        {
        if ($Translit[$CHR] -cne $Null ) 
            {$outCHR += $Translit[$CHR]}
        else
            {$outCHR += $CHR}
        }
    Write-Output $outCHR
 }

function checkLogin ($login){
    $check = Get-ADUser -LDAPFilter "(sAMAccountName=$login)"
    return $check
}

function setLogin ($attempt,$sn,$gn,$ini){
    
    #Test
    if([string]::IsNullOrWhiteSpace($sn) -or [string]::IsNullOrWhiteSpace($gn) -or [string]::IsNullOrWhiteSpace($ini)){
        Write-Host -ForegroundColor Red "Some fields name is empty."
        return
    }

    switch ($attempt){
        #first letters
        1 {$sam = $sn.substring(0,1) + $gn.substring(0,1) + $ini.substring(0,1)
            Write-Host "Create login attempt 1 = $sam"
        } 
        #первые буквы, и 2 первые буквы имени
        2 {$sam = $sn.substring(0,1) + $gn.substring(0,2) + $ini.substring(0,1)
            Write-Host "Create login attempt 2 = $sam"
        }
        #первые буквы, и 2 первые буквы фамилии  
        3 {$sam = $sn.substring(0,1) + $gn.substring(0,1) + $ini.substring(0,2)
            Write-Host "Create login attempt 3 = $sam"
        } 
    }    
    $sam=Translit($sam)
    return $sam
}

function WriteLog ($msg){
    $msg | Out-File $log -Append -encoding unicode
}

function getOU ($company){
    switch ($_.Company){
        #'ООО "КОМПАНИЯ"'    {$path = "ou=КОМПАНИЯ,ou=Барнаул,ou=Пользователи,dc=domain,dc=local"}
        default             {$path = "ou=Новые,ou=Пользователи,dc=domain,dc=local"}
    }
    return $path    
}

function get-domain ($company){
    switch ($_.Company){
        #'ООО "КОМПАНИЯ"'    {$upn = "domain.local"}
        default             {$upn = "domain.local"}
    }
    return $upn    
}

function new-user ($Header){
    
    Write-Host -ForegroundColor Green "Person $fullname does't exist, let's create login"                   
        Write-Host "Creating login for $fullname" 
        $sam=setLogin 1 $_.SN $_.GivenName $_.Patronymic
        
        Write-Host "Checking login $sam for uniquiness"
        $existLogin = checkLogin($sam)
        
        if ($existLogin){
            Write-Host " Login $sam is busy, trying create another, attempt 2"
            $sam=setLogin 2 $_.SN $_.GivenName $_.Patronymic

            Write-Host "Checking login $sam for uniquiness"
            $existLogin =checkLogin($sam)
            if ($existLogin){
                Write-Host " Login $sam is busy, trying create another, attempt 3"
                $sam=setLogin 3 $_.SN $_.GivenName $_.Patronymic
                    
                Write-Host "Checking login $sam for uniquiness"
                $existLogin = checkLogin($sam)
                if ($existLogin){
                    Write-Host " Login $sam is busy, trying create another, attempt 4"
                    $sam = $_.sn                      
                }
                    Write-Host "Check login $sam for uniquiness"
                    $existLogin =checkLogin($sam)
                    if ($existLogin){
                        Write-Host "Login $sam is busy, creating skipped"
                        WriteLog "Login $sam is busy, creating skipped"
                        return
                    }
            }
        }
        else {
            Write-Host "Generated login $sam is unique"
        }
 
    
    $sam = $sam.ToLower()
    $SamAccountName = $sam
    Write-Host -ForegroundColor Gray "SamAccountName= "$SamAccountName
    Write-Host -ForegroundColor Gray "Title= "$_.Title
    Write-Host -ForegroundColor Gray "Department= "$_.Department
            

    # SET PROPERTIES
    #---------------
    #$password = setPassword
    $password = $sam+$sam
    $password = ConvertTo-SecureString -AsPlainText "$password" -force

    $country = "RU"

    
    #-inicials
    $initials=$_.GivenName.chars(0)+$_.Patronymic.chars(0)
    Write-Host "Initials = "$initials
    
    #-departament
    #remove numbers before department
    $dep = ($_.Department).Split(" ")
    $dep=$dep[1..($dep.Length-1)]
    $dep=[string]$dep
    
    #-ou
    $ou=getOU $_.Company
    
    #-upn
    $domain=get-domain $_.Company
    $upn = $sam + "@" + "$domain"

    New-ADuser  -Name $sam `
                -Initials $initials `
                -Surname $_.Sn `
                -UserPrincipalName $upn `
                -SamAccountName $SamAccountName  `
                -City $_.City `
                -StreetAddress $_.StreetAddress `
                -Department $dep `
                -GivenName $_.GivenName `
                -Title $_.Title `
                -Description $_.Description `
                -Division $_.Division `
                -Path "$ou" `
                -AccountPassword $password `
                -Company $_.Company `
                -Country $country  `
                -OfficePhone $_.OfficePhone `
                -PostalCode $_.PostCode `
                -HomePhone $_.HomePhone `
                -MobilePhone $_.MobilePhone

    
# пауза для синхронизации AD
    Start-Sleep -Seconds 15

    # SET PROPERTIES
    #---------------
    #-ipPhone
    if ($_.OfficePhone) {
        Get-ADUser -Identity $sam | set-aduser -Replace @{ipPhone=$_.OfficePhone}
    }

     #-Manager
     if ($_.Manager){
        $Manager=[string]$_.Manager
        $samManager = (Get-ADUser -Filter "Name  -eq '$Manager'").SamAccountName
        Set-ADUser -Identity $sam -Manager $samManager
     }
    
    
    #-DisplayName
    $newdn = (Get-ADUser $sam).DistinguishedName
    Write-Host "Rename for good looking CN"
    $newname=$_.SN+" "+$_.GivenName+" "+$_.Patronymic
    Rename-ADObject -Identity $newdn -NewName  $newname
    Set-ADUser $sam -DisplayName $newname

    #-ChangePasswordAtLogon
    Set-ADUser $sam -ChangePasswordAtLogon $true
    Enable-ADAccount $sam
    Write-Host -ForegroundColor Green "User was successfully created!"

    #Общий лог
    $fio = (Get-ADUser $sam).Name
    WriteLog "Учетная запись создана для сотрудника '$fio' : логин $sam, пароль $sam$sam"
    send-mail "Учетная запись создана для сотрудника '$fio' : логин $sam, пароль $sam$sam"

}

function send-mail {
    param ($body)
    Send-MailMessage    -From $SenderEmail `
                        -To $RecipientEmail `
                        -Subject $SubjectMail `
                        -Body $body `
                        -SmtpServer $IPMailServer `
                        -Port 587 `
                        -Credential $cred `
                        -Encoding $encoding   
}

function add-mailbox ($login) {
         
    Invoke-Command  -ConfigurationName $ConfigurationName -ConnectionUri $ConnectionUri `
                    -scriptblock {param ($login,$Database) Enable-Mailbox -Identity $login -Database $Database} `
                    -ArgumentList $login,$Database
  
}

WriteLog $(Get-Date -UFormat "%A %d/%m/%Y %R %Z")

Import-CSV -Path $CSVfile -Header $Header | ForEach-Object {
    
    $fullname = $_.SN+" "+$_.GivenName+" "+$_.Patronymic       
 
    If(!(Get-ADUser -f ('Name -eq $fullname') )){
            new-user ($Header)
            add-mailbox($login)    
    }

    else {
      #узнаем логин для учетной записи
      $login = (Get-ADUser -f ('Name -eq $fullname')).SamAccountName 

      Write-Host -ForegroundColor Green  "Учетная запись для '$fullname' уже существует."
      WriteLog "Для сотрудника '$fullname' (логин $login) учетная запись уже существует. Для получения пароля обратитесь к администратору"
      send-mail "Для сотрудника '$fullname' (логин $login) учетная запись уже существует. Для получения пароля обратитесь к администратору"
      
    }
}