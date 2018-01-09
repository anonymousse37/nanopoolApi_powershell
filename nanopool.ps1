#AUTHOR  : anonymousse37
#DATE    : 09/01/2018
#REV     : 1.00

cls;
#USER VAR#########################################################################################################################################################################

#Wallet whitout '0x'
$wallet = 'you_wallet';
$payout = 0.2;
#CryptoCurrency you are mining (lowercase only and check on nanopool the associated trigram to your cryptocurrency
$cc = 'eth'

#FUNCTIONS########################################################################################################################################################################

Function Get-EpochTime()
{
    $D = ('01/01/1970' -as [DateTime])
    [int]$int_nonce = ((New-TimeSpan -Start $D -End ([DateTime]::UtcNow)).TotalSeconds -as [string])
    [string]$str_nonce = ($int_nonce -as [string])
    return $str_nonce
}

Function ConvertFrom-EpochDate 
{ 
   Param ([double]$epochTimeStamp)
   [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochTimeStamp))
}

#MAIN#############################################################################################################################################################################

#Initializing DATA
        $index = 0
$balance_total = 0
       $time_i = new-object    int[] 100000
    $balance_i = new-object double[] 100000

#Url of json api requests
$nanopoolApi_req_00 = 'https://api.nanopool.org/v1/' +$cc + '/user/' + $wallet
$nanopoolApi_req_01 = 'https://api.nanopool.org/v1/' +$cc + '/prices'

$loop_i = 1
$start_over = 'False'
$date_0 = Get-EpochTime;
#Starting the loop
while (1) 
{
    #Date when the loop $loop_i started
    $date_i = Get-EpochTime;

    #Case 0 : The arrays to store the data have reach its max bound or a payout occurred
    if ( $start_over -eq 'True' )
    {
        $index = 0
    }

    #Converting requests to json Objects
    $json_nanopoolApi_req_00 = (Invoke-WebRequest $nanopoolApi_req_00).content | ConvertFrom-Json
    $json_nanopoolApi_req_01 = (Invoke-WebRequest $nanopoolApi_req_01).content | ConvertFrom-Json

    $json_nanopoolApi_req_status = 'False'
    #Checking if nanopool's API requests returned the expected values to continue the data processing
    if ( ( $json_nanopoolApi_req_00.status -eq 'True' ) -and ( $json_nanopoolApi_req_01.status -eq 'True' ) )
    {   
        $json_nanopoolApi_req_status = 'True'

        #Retrieve the usefull data from nanopool's API requests
        $balance_unconfirmed = [double]$json_nanopoolApi_req_00.data.unconfirmed_balance
        $balance_confirmed   = [double]$json_nanopoolApi_req_00.data.balance
        $hashrate_current    = [double]$json_nanopoolApi_req_00.data.hashrate
        $hashrate_avg_h01    = [double]$json_nanopoolApi_req_00.data.avghashrate.h1
        $hashrate_avg_h03    = [double]$json_nanopoolApi_req_00.data.avghashrate.h3
        $hashrate_avg_h06    = [double]$json_nanopoolApi_req_00.data.avghashrate.h6
        $hashrate_avg_h12    = [double]$json_nanopoolApi_req_00.data.avghashrate.h12
        $hashrate_avg_h24    = [double]$json_nanopoolApi_req_00.data.avghashrate.h24
        $cc_to_eur_nanopool = [double]$json_nanopoolApi_req_01.data.price_eur
        $balance_total = [double]($balance_confirmed + $balance_unconfirmed)
        $cc_total_eur = [double]($cc_to_eur_nanopool*$balance_total)

        #Processing DATA
        #Case 1 : if index = 0 then initializing the usefull data
        if ( $index -eq 0 )
        {
               $time_i[0] = $date_i
            $balance_i[0] = $balance_confirmed
            $index++
        }
        #Case 2 : index = 10000 then we start over
        ElseIf ( $index -eq 10000 )
        {
            $start_over = 'True'
        }
        #Case 3 : index in [1;99999] 
        else
        {
            #Case 3.1 : The current value of balance_confirmed is superior to the previous one ( shares have been validated and corresponding ETH have been added to the balance )
            if ( $balance_confirmed -gt $balance_i[$index-1] )
            {
                #Storing the time and balance_confirmed
                    $time_i[$index] = $date_i
                $balance_i[$index] = $balance_confirmed
            
                #Case 3.1.1 : 
                # $index = 0 : Initialisation
                # $index = 1 : An incrementation of balanced_confirmed has occurred so we can assert that the next incrementation will start at the right date
                # $index = 2 : An incrementation of balanced_confirmed has occurred so now we have a real spent time between two incrementations and we can compute the data
                if ( $index -ge 2 )
                {
                    #We can compute the mining speed ( ETH/sec )
                    $balance_ti = $balance_i[$index] - $balance_i[1]
                    $ti         =    $time_i[$index] -    $time_i[1]
            
                    #Statistics ETH/period
                    $cc_per_sec = $balance_ti/$ti
                    $cc_per_min = $cc_per_sec*60
                    $cc_per_hou = $cc_per_min*60
                    $cc_per_day = $cc_per_hou*24
                    $cc_per_wee = $cc_per_day*7
                    $cc_per_mon = $cc_per_day*30.42
                    $cc_per_yea = $cc_per_day*365
            
                    #Statistics EUR/period
                    $eur_per_sec = $cc_per_sec*$cc_to_eur_nanopool
                    $eur_per_min = $cc_per_min*$cc_to_eur_nanopool
                    $eur_per_hou = $cc_per_hou*$cc_to_eur_nanopool
                    $eur_per_day = $cc_per_day*$cc_to_eur_nanopool
                    $eur_per_wee = $cc_per_wee*$cc_to_eur_nanopool
                    $eur_per_mon = $cc_per_mon*$cc_to_eur_nanopool
                    $eur_per_yea = $cc_per_yea*$cc_to_eur_nanopool    


                    $nanopoolApi_req_02      = 'https://api.nanopool.org/v1/'+ $cc + '/approximated_earnings/' + $hashrate_avg_h06
                    $json_nanopoolApi_req_02 = (Invoke-WebRequest $nanopoolApi_req_02).content | ConvertFrom-Json
                    if ( $json_nanopoolApi_req_02.status -eq 'True' )
                    {
                        $ncc_min_coins = [double]$json_nanopoolApi_req_02.data.minute.coins
                        $ncc_min_euros = [double]$json_nanopoolApi_req_02.data.minute.euros
                        $ncc_hou_coins = [double]$json_nanopoolApi_req_02.data.hour.coins
                        $ncc_hou_euros = [double]$json_nanopoolApi_req_02.data.hour.euros
                        $ncc_day_coins = [double]$json_nanopoolApi_req_02.data.day.coins
                        $ncc_day_euros = [double]$json_nanopoolApi_req_02.data.day.euros
                        $ncc_wee_coins = [double]$json_nanopoolApi_req_02.data.week.coins
                        $ncc_wee_euros = [double]$json_nanopoolApi_req_02.data.week.euros
                        $ncc_mon_coins = [double]$json_nanopoolApi_req_02.data.month.coins
                        $ncc_mon_euros = [double]$json_nanopoolApi_req_02.data.month.euros
                    }
                    else { $json_nanopoolApi_req_status = 'False' }
                }
                $index++;
            }
            #Case 3.2 : balanced_confirmed should be equal to 0 or is inferior to the previous balanced_confirmed value due to a payout then start over
            else 
            {
                $start_over = 'True'
            }
        }
    }
    
    #OUTPUT####################################################################################################################################################################### 
    
    if ( $json_nanopoolApi_req_status -eq 'True' )
    {
        cls;
        '';
        write-host '----------------------- GENERAL INFORMATIONS -----------------------' -foregroundcolor "red"
        'LOOP N°' + $loop_i
        'Incrementations    : ' + ($index-1)
        'Script started on  : ' + (ConvertFrom-EpochDate $date_0)
        $t_tmp = Get-EpochTime;
        $t_format = new-timespan -seconds ($t_tmp - $date_0)
        'Script running for : ' + $t_format 
        'ETH to payout = ' + [math]::Round(($payout - $balance_i[$index-1]),3)
        if ( $index -ge 3 )
        {
            $payout_time =  new-timespan -seconds (($payout - $balance_i[$index-1])/$cc_per_sec);
            'Payout will be reach in ' + $payout_time.Days + ' Days and ' + $payout_time.Hours + ':' +  $payout_time.Minutes + ':' + $payout_time.Seconds
            $payout_date = ConvertFrom-EpochDate ( ([int]$t + [int](($payout - $balance_i[$index-1])/$cc_per_sec)) )
            'Time to payout ' + $payout_date
        }
        ''
        write-host '------------------------ NANOPOOL STATISTICS ------------------------' -foregroundcolor "red"
        '' 
        write-host '< HASHRATE STATS >' -foregroundcolor "green"
        'Hashrate : Current = ' + $hashrate_current + ' Mh/s'
        'Hashrate : H01     = ' + $hashrate_avg_h01 + ' Mh/s' 
        'Hashrate : H03     = ' + $hashrate_avg_h03 + ' Mh/s' 
        'Hashrate : H06     = ' + $hashrate_avg_h06 + ' Mh/s' 
        'Hashrate : H12     = ' + $hashrate_avg_h12 + ' Mh/s' 
        'Hashrate : H24     = ' + $hashrate_avg_h24 + ' Mh/s' 
        '' 
        write-host '< CRYPTOCURRENCY STATS >' -foregroundcolor "green"
        'Balance : unconfirmed = ' + $balance_unconfirmed + ' ETH'
        'Balance : confirmed   = ' + $balance_confirmed + ' ETH'
        'Balance : total       = ' +$balance_total + ' ETH'
        '1 ' + $cc + '                 = ' + $cc_to_eur_nanopool + ' €'  
        'Total EUR             = ' + [math]::Round($cc_total_eur,2) + ' €' 
        ''
    
        write-host '< CRYPTOCURRENCY MINING STATS >'-foregroundcolor "green"
        if ( $index -ge 3 )
        {
            write-host '< CRYPTOCURRENCY MINING STATS : script >' -foregroundcolor "yellow"
            'ETH per sec = ' + [math]::Round($cc_per_sec,3) + '     | EUR per sec = ' + [math]::Round($eur_per_sec,2);
            'ETH per min = ' + [math]::Round($cc_per_min,3) + '     | EUR per min = ' + [math]::Round($eur_per_min,2);
            'ETH per hou = ' + [math]::Round($cc_per_hou,3) + ' | EUR per hou = ' + [math]::Round($eur_per_hou,2);
            'ETH per day = ' + [math]::Round($cc_per_day,3) + ' | EUR per day = ' + [math]::Round($eur_per_day,2);
            'ETH per wee = ' + [math]::Round($cc_per_wee,3) + ' | EUR per wee = ' + [math]::Round($eur_per_wee,2);
            'ETH per mon = ' + [math]::Round($cc_per_mon,3) + ' | EUR per mon = ' + [math]::Round($eur_per_mon,2);
            'ETH per yea = ' + [math]::Round($cc_per_yea,3) + ' | EUR per yea = ' + [math]::Round($eur_per_yea,2);
            ''
            write-host '< CRYPTOCURRENCY MINING STATS : nanopool >' -foregroundcolor "yellow"
            'ETH per sec = ' + [math]::Round($ncc_min_coins/60,3) + '     | EUR per min = ' + [math]::Round($ncc_min_euros/60,2);
            'ETH per min = ' + [math]::Round($ncc_min_coins,3) + '     | EUR per min = ' + [math]::Round($ncc_min_euros,2);
            'ETH per hou = ' + [math]::Round($ncc_hou_coins,3) + ' | EUR per hou = ' + [math]::Round($ncc_hou_euros,2);
            'ETH per day = ' + [math]::Round($ncc_day_coins,3) + ' | EUR per day = ' + [math]::Round($ncc_day_euros,2);
            'ETH per wee = ' + [math]::Round($ncc_wee_coins,3) + ' | EUR per wee = ' + [math]::Round($ncc_wee_euros,2);
            'ETH per mon = ' + [math]::Round($ncc_mon_coins,3) + ' | EUR per mon = ' + [math]::Round($ncc_mon_euros,2);
            'ETH per yea = ' + [math]::Round(($ncc_mon_coins*12),3) + ' | EUR per day = ' + [math]::Round(($ncc_mon_euros*12),2);
            ''
        }
        else 
        {
            '- CRYPTOCURRENCY mining stats cannot be displayed at the moment.'
            '- It will take about 15 minutes to get the first values.'
            '- Values will become more and more accurate with time.'
            '- 6 hours required to display the first accurate values.'
        }
    }
    else
    {
        ''
        'Every or some API requests did not suceed, waiting for the next loop to refresh data'
        ''
    }

    $loop_i++;
    Start-Sleep -s 15
} 
