global with sharing class AccountsNearby {
    Account a;

    public ApexPages.StandardSetController accountsController {get; set;}

    public String selectedAccount               { get; set; }
    public String selectedAccountName           { get; set; }
    public String accId                         { get; set; }
    public String channel                       { get; set; }
    public String results                       { get; set; }
    public String radius                        { get; set; }
    public boolean BFFriendly                   { get; set; }
    public boolean myAccountsFilter             { get; set; }
    public String isAfterHoursApp               { get; set; }
    public String highlight                     { get; set; }
    public String accountFilterId               { get; set; }
    public String lat                           { get; set; }
    public String lon                           { get; set; }
    public String currentlat                    { get; set; }
    public String currentlon                    { get; set; }
    public String currentMarket                 { get; set; }
    public String distanceIdentifier            { get; set; }
    public String marketLevel                   { get; set; }
    public transient String myAccounts          { get; set; }
    public transient String myVIPAccounts       { get; set; }
    public String serializedMarketList          { get; set; }
    public String serializedCityList            { get; set; }
    public Date eventDate                       { get; set; }
    public String displayDate                   { get; set; }
    
    public Integer dateCalc                     { get; set; }
    //public User u {get;set;}
    public String userType                      { get; set; }
    public String userId                        { get; set; }
    public String urlPrefix                     { get; set; }
    public Boolean showOnlyTheseAccounts        { get; set; }
    public Boolean enableGoogleSearch           { get; set; }
    public Boolean isTableauReady               { get; set; }
    
    public Boolean marketConfigured             { get; set; }

    public List<string> channelOptions          { set; }
    public List<string> resultsOptions          { set; }
    public List<string> radiusOptions           { set; }
    public List<string> highlightOptions        { set; }

    public List<Account> accountList = new List<Account>();
    public List<Accounts_VIP__c> vipAccountsList = new List<Accounts_VIP__c>();
    public List<Event> eventList = new list<Event>();
    public List<Id> eventAccounts = new list<Id>();

    public AccountsNearby(ApexPages.StandardController controller) {
        userType = UserInfo.getUserType();
        if(userType != 'Standard'){
            urlPrefix = '/sales';
        }else{
            urlPrefix = '';
        }
        userId = UserInfo.getUserId();
        
        List<Market__c> markets = [SELECT Id, Name, AccountsNearby_Calendar_Check_Default__c, AccountsNearby_Enable_Google_Search__c, Is_Tableau_Ready__c FROM Market__c ORDER BY Name];
        serializedMarketList = JSON.serialize(markets);
        
        // Find the user's market, populate default view Calendar checkbox state and get Google Search box enable state
        showOnlyTheseAccounts = false;
        enableGoogleSearch = false;
        isTableauReady = false;
        currentMarket = '';
        marketConfigured = false;
        try{
            this.a = (Account)controller.getRecord();
            a = [Select Id, Channel__c, Name, Geolocation__Latitude__s, Geolocation__Longitude__s, Last_Visit_Date__c, Outlet_Class__r.Name, Market__r.Name from Account where Id =:a.Id];
            lat = a.Geolocation__Latitude__s.toPlainString();
            lon = a.Geolocation__Longitude__s.toPlainString();
            currentlat = lat;
            currentlon = lon;
            currentMarket = a.Market__r.Name;
            System.debug('a: '+a);
        } catch(NullPointerException geocode) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Account Not Geocoded! Please contact your system administrator!'));
            system.debug(geocode);
        } catch(Exception e){
            system.debug(e);
            //filter();
        }
System.debug('currentMarket: ' + currentMarket);
        if (currentMarket == '') {
            List<User> usr = [SELECT Market__c FROM User WHERE Id = :userId AND Market__c != null LIMIT 1];
            if(usr.size() > 0) {
                String userMarket = usr[0].Market__c;
                System.debug('userMarket: ' + userMarket);
                if (userMarket.length() > 0 && userMarket !=  'US') {
                    currentMarket = userMarket;
                }
            }            
        }
System.debug('[after user] currentMarket: ' + currentMarket);
        
        accountFilterId = Label.Select_a_List_View;
        channel = 'ALL';
        results = '25';
        radius = '10';
        distanceIdentifier = 'km';        
        BFFriendly = false;
        isAfterHoursApp = ApexPages.currentPage().getParameters().get('afterhours');
        if (isAfterHoursApp == null) { isAfterHoursApp = '0'; }
        if (isAfterHoursApp=='1') { 
            BFFriendly = true; 

            /*
            List<AccountLocation> locations = new List<AccountLocation>();
            List<AggregateResult> cities = [SELECT Account__r.ShippingCity, Account__r.ShippingCountry FROM Accounts_VIP__c GROUP BY Account__r.ShippingCountry, Account__r.ShippingCity ORDER BY Account__r.ShippingCountry, Account__r.ShippingCity];            
            if (cities != null && cities.size() > 0) {
                for(AggregateResult ar : cities) {
                    locations.add(new AccountLocation(String.valueof(ar.get('ShippingCity')), String.valueOf(ar.get('ShippingCountry'))));
                }
            }
            Boolean found = false;
            */
            List<Accounts_VIP_Location__c> accountLocations = [SELECT City__c, Country__c, Location__latitude__s, Location__longitude__s FROM Accounts_VIP_Location__c ORDER BY Country__c, City__c];
            if (accountLocations != null && accountLocations.size() > 0) {
                /*
                for(Accounts_VIP_Location__c vipLocation : accountLocations) {
                    found = false;
                    for(AccountLocation al : locations) {
                        if (al.country == vipLocation.Country__c && al.city == vipLocation.City__c) {
                            found = true; break;
                        }
                    }

                    if (!found) {
                        locations.add(new AccountLocation(vipLocation.City__c, vipLocation.Country__c, String.valueOf(vipLocation.Location__latitude__s), String.valueOf(vipLocation.Location__longitude__s)));
                    }
                }
                */
                serializedCityList = JSON.serialize(accountLocations);
            } else {
                serializedCityList = '';
            }

            /*
            if (cities != null && cities.size() > 0) {
                serializedCityList = JSON.serialize(cities);
            } 
            */   
        }
        
        myAccountsFilter = false;
        highlight = 'Channel';
        eventDate = system.today();
        displayDate = Label.Today;
        dateCalc = 0;
        if (UserInfo.getLocale() == 'en_US') {
            distanceIdentifier = 'mi';
        }

        getAccountList();
        getVIPAccountList();
        getEventList();
                
        if (currentMarket.length() == 0) {
            if (accountList.size() > 0) {
                currentMarket = accountList[0].Market__r.Name;
            } else if(vipAccountsList.size() > 0) {
                currentMarket = vipAccountsList[0].Market_Name__c;
            }
        }
System.debug('[after account list] currentMarket: ' + currentMarket);
        
        if (currentMarket.length() > 0) { 
            getMarketConfiguration(currentMarket);            
        }
        
    }

    public PageReference forwardToCustomAuthPage() {
        system.debug('UserInfo.getUserType(): '+UserInfo.getUserType());
        if(UserInfo.getUserType() == 'Guest'){
            return new PageReference('/CommunitiesLogin');
        }
        else{
            return null;
        }
    }

    public Account getA(){
        if(accId != null){
            a = [SELECT Id, Channel__c, Name, Geolocation__Latitude__s, Geolocation__Longitude__s, Last_Visit_Date__c, Outlet_Class__r.Name, ShippingStreet, ShippingCity, Phone, Market__r.Name, VIP_Account__c, Expense__c, Key_Product_Ranging__c, Description, Recommended_Food__c, Suggested_Serves__c  FROM Account WHERE id = :accId LIMIT 1];
            lat = a.Geolocation__Latitude__s.toPlainString();
            lon = a.Geolocation__Longitude__s.toPlainString();
            currentlat = lat;
            currentlon = lon;
        }
        return a;
    }

    public list<Account> getAccountList(){
        return accountList;
    }
    public list<Accounts_VIP__c> getVipAccountList() {
        return vipAccountsList;
    }

    public list<selectOption> getChannelOptions(){
        List<RecordTypeInfo> l_RecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfos();
        List<String> l_availableRecordTypes = new List<String>();
        for(RecordTypeInfo rti : l_RecordTypes) {
            //System.debug('recordtype: ' + rti.getName() + ' isavailable: ' + rti.isAvailable());
            if (rti.IsAvailable()) {
                l_availableRecordTypes.add(rti.getName());
            }
        }
          
        //System.debug('# of available recordtypes: ' + l_availableRecordTypes.size());
        List<Salesforce_Picklist_Controlling_Values__c> l_values = [SELECT Id, Name, Controller__c, Controller_Value__c, Value__c FROM Salesforce_Picklist_Controlling_Values__c WHERE Object_Name__c = 'Account' AND Field_Name__c = 'Channel__c' AND Is_Active__c = true AND Controller__c = 'RecordType' AND Controller_Value__c =:l_availableRecordTypes ORDER BY Value__c];
        Set<String> s_availableValues = new Set<String>();
        for(Salesforce_Picklist_Controlling_Values__c spcv : l_values) {
            //System.debug('spcv.value: ' + spcv.Value__c + ', controller: ' + spcv.Controller__c + ', controller.value: ' + spcv.Controller_Value__c);
            s_availableValues.add(spcv.Value__c);
        }

        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('ALL',''+Label.Channel+''));
        optionList.add(new SelectOption('ALL',''+Label.All+''));
        /*
        optionList.add(new SelectOption('On',''+Label.ON+''));
        optionList.add(new SelectOption('Off',''+Label.OFF+''));
        */

        List<Schema.PicklistEntry> channelValues = Account.Channel__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry pe : channelValues) {
            if (pe.isActive() && pe.getLabel() != 'N/A' && s_availableValues.contains(pe.getValue())) {
                optionList.add(new SelectOption(pe.getValue(), pe.getLabel()));
            }
        }
        return optionList;
    }

    public list<selectOption> getResultsOptions(){
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('25',''+Label.Results+''));
        optionList.add(new SelectOption('10','10'));
        optionList.add(new SelectOption('25','25'));
        //optionList.add(new SelectOption('50','50'));
        //optionList.add(new SelectOption('100','100'));
        return optionList;
    }

    public list<selectOption> getRadiusOptions(){
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('10',''+Label.Radius+''));
        optionList.add(new SelectOption('1','1 ' + distanceIdentifier));
        optionList.add(new SelectOption('5','5 ' + distanceIdentifier));
        optionList.add(new SelectOption('10','10 ' + distanceIdentifier));
        optionList.add(new SelectOption('25','25 ' + distanceIdentifier));
        optionList.add(new SelectOption('50','50 ' + distanceIdentifier));
        optionList.add(new SelectOption('100','100 ' + distanceIdentifier));
        return optionList;
    }

    public list<selectOption> getHighlightOptions(){
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('Channel',''+Label.Channel+''));
        optionList.add(new SelectOption('Last Visit Date',''+Label.Last_Visit_Date+''));
        if (Account.Outlet_Class__c.getDescribe().isAccessible()) {
            optionList.add(new SelectOption('Outlet Class',''+Label.Outlet_Class+''));
        }
        return optionList;
    }
    
    public list<Event> getEventList(){
        eventList = [SELECT Id, Subject, Closed__c, Objectives__c, WhatId, Account.Name, Account.Geolocation__Latitude__s, Account.Geolocation__Longitude__s, AccountId, ActivityDate, StartDateTime, EndDateTime FROM Event WHERE OwnerId=:UserInfo.getUserId() AND ActivityDate = :eventDate ORDER BY StartDateTime ASC];
        if (eventList == null) { eventList = new List<Event>(); }
        
        for(Event e:eventList){
            if(e.AccountId != null){
                eventAccounts.add(e.AccountId);
            }
        }            
        
        return eventList;
    }

    private void getMarketConfiguration(String currentMarket) {
        System.debug('get market configuration for market: ' + currentMarket);
        List<Market__c> mkt = [SELECT AccountsNearby_Calendar_Check_Default__c, AccountsNearby_Enable_Google_Search__c, Is_Tableau_Ready__c FROM Market__c WHERE Name = :currentMarket LIMIT 1];
        if(mkt.size() > 0) {
            System.debug('market calendar default: ' + mkt[0].AccountsNearby_Calendar_Check_Default__c);
            showOnlyTheseAccounts = mkt[0].AccountsNearby_Calendar_Check_Default__c;
            System.debug('market enable google search: ' + mkt[0].AccountsNearby_Enable_Google_Search__c);
            enableGoogleSearch = mkt[0].AccountsNearby_Enable_Google_Search__c;
            isTableauReady = mkt[0].Is_Tableau_Ready__c;
            System.debug('isTableauReady: ' + isTableauReady);
            marketConfigured = true;
        }
        
    }
    
    public PageReference changeDay(){
        eventList.clear();
        eventAccounts.clear();
        eventDate = eventDate.addDays(dateCalc);
        if(eventDate == system.Today()){
            displayDate = Label.Today;
        }else{
            displayDate = eventDate.format();
        }
        eventList = [SELECT Id, Subject, Objectives__c, WhatId, Account.Name, Account.Geolocation__Latitude__s, Account.Geolocation__Longitude__s, AccountId, ActivityDate, StartDateTime, EndDateTime FROM Event WHERE OwnerId=:UserInfo.getUserId() AND ActivityDate = :eventDate ORDER BY StartDateTime ASC];
        for(Event e:eventList){
            if(e.AccountId != null){
                eventAccounts.add(e.AccountId);
            }
        }
        return null;
    }

    public PageReference filter(){
        accountList.clear();
        vipAccountsList.clear();

        String queryString =
            'SELECT Id, Channel__c, Name, Geolocation__Latitude__s, Geolocation__Longitude__s, Last_Visit_Date__c, Market__c, Market__r.Name, Outlet_Class__r.Name, ' +
                'ShippingStreet, ShippingCity, ShippingState, Phone, Website, VIP_Account__c, Expense__c, Key_Product_Ranging__c, Description, Recommended_Food__c, Suggested_Serves__c ' +
            'FROM Account WHERE';
        String whereClause = '';
        if (isAfterHoursApp == '1') {
            /*
            queryString = 'SELECT Account__c, Account__r.Channel__c, Account__r.Name, Account__r.Geolocation__Latitude__s, Account__r.Geolocation__Longitude__s, Account__r.Last_Visit_Date__c, Account__r.Market__c, Account__r.Market__r.Name, Account__r.Outlet_Class__r.Name, ' +
                'Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.Phone, Account__r.Website, Account__r.VIP_Account__c, Account__r.Expense__c, Account__r.Key_Product_Ranging__c, Account__r.Description, Account__r.Recommended_Food__c, Account__r.Suggested_Serves__c ' +
            */
            queryString = 'SELECT Account__c, Channel__c, Account_Name__c, Geolocation__Latitude__s, Geolocation__Longitude__s, Last_Visit_Date__c, Market__c, Market_Name__c, Outlet_Class__r.Name, ' +
                'ShippingStreet__c, ShippingCity__c, ShippingState__c, Phone__c, Website__c, VIP_Account__c, Expense__c, Key_Product_Ranging__c, Description__c, Recommended_Food__c, Suggested_Serves__c ' +
                'FROM Accounts_VIP__c WHERE ';
        } else {
            if(BFFriendly){
                whereClause += ' VIP_Account__c = true ';
            }
            if(myAccountsFilter){
                if (whereClause.length() > 0) { whereClause += ' AND '; }
                whereClause += ' OwnerId = \''+userId+'\' ';
            }            
        }
        // Remove inactive Accounts from map
        if (isAfterHoursApp == '0') {
            if (whereClause.length() > 0) { whereClause += ' AND '; }
            whereClause += ' Status__c != \'Inactive\' ';
        }
        
        if(channel != 'ALL'){
            if (whereClause.length() > 0) { whereClause += ' AND '; }
            whereClause += ' Channel__c LIKE \''+channel+'%\' ';
        }
        if (isAfterHoursApp == '0') {
            if(currentMarket != null || currentMarket != ''){
                if (marketLevel == 'State'){
                    if (whereClause.length() > 0) { whereClause += ' AND '; }
                    whereClause +=' (Market__r.Name LIKE \'%'+currentMarket+'%\' OR Market__r.Name =\'Global Travel Retail\') ';
                } else {
                    if (whereClause.length() > 0) { whereClause += ' AND '; }
                    whereClause +=' (Market__r.Country_ISO_Code_2__c = \''+currentMarket+'\' OR Market__r.Name =\'Global Travel Retail\')';
                    //queryString+=' Shipping'+marketLevel+' = \''+currentMarket+'\' AND';
                }
            }            
        }
        
        System.debug('[filter] lat: ' + lat + ', lon: ' + lon);
        if (lat != null && lat != '' && lon != null & lon != '') {
            if (whereClause.length() > 0) { whereClause += ' AND '; }
            whereClause +=' DISTANCE(Geolocation__c, GEOLOCATION('+lat+','+lon+'), \'' + distanceIdentifier + '\') < '+ radius;
            whereClause +=' ORDER BY DISTANCE(Geolocation__c, GEOLOCATION('+lat+','+lon+'), \'' + distanceIdentifier + '\')';
        }
        queryString += whereClause + ' LIMIT ' + results;
        System.debug(queryString);
        if (isAfterHoursApp == '0') {
	        accountList = database.query(queryString);
            myAccounts = JSON.serialize(accountList);
        } else {
            accountList.clear();
            vipAccountsList = database.query(queryString);
            myVIPAccounts = JSON.serialize(vipAccountsList);
            /*
            for(Accounts_VIP__c vip : vipAccountsList) {
				//accountList.add(vip.Account__r);                
                accountList.add(new Account(Id=vip.Account__c, 
                    Name=vip.Account_Name__c,
                    Channel__c=vip.Channel__c,
                    Outlet_Class__c=vip.Outlet_Class__c,
                    ShippingStreet=vip.ShippingStreet__c,
                    ShippingCity=vip.ShippingCity__c,
                    ShippingState=vip.ShippingState__c,
                    Phone=vip.Phone__c,
                    Website=vip.Website__c,
                    Geolocation__Latitude__s = vip.Geolocation__Latitude__s,
                    Geolocation__Longitude__s = vip.Geolocation__Longitude__s
                ));
            }
            */

        }

        if(accountList.size() < 1 && vipAccountsList.size() < 1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.No_Accounts_Returned));
            return null;
        }
        /*
        System.debug('get accountList currentMarket: ' + currentMarket);
        if (!marketConfigured) { 
            currentMarket = accountList[0].Market__r.Name;
            getMarketConfiguration(currentMarket);            
        }
        */

        return null;
    }

    public PageReference eventFilter(){
        accountList.clear();
        string accountIds ='(';
        for(id a:eventAccounts){
            accountIds+='\''+a+'\',';
        }
        accountIds = accountIds.substring(0,(accountIds.length()-1));
        accountIds+=')';
        String queryString =
            'SELECT Id, Channel__c, Name, Geolocation__Latitude__s, Geolocation__Longitude__s, Last_Visit_Date__c, Outlet_Class__r.Name, ' +
                'ShippingStreet, Phone ' +
            'FROM Account WHERE Id in ' +accountIds;
        queryString+=' ORDER BY DISTANCE(Geolocation__c, GEOLOCATION('+lat+','+lon+'), \'' + distanceIdentifier + '\')';
        accountList = database.query(queryString);
        if(accountList.size() <1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your filter returned 0 accounts, please try a different filter'));
            return null;
        }
        myAccounts = JSON.serialize(accountList);
        return null;

    }

    public PageReference newAccountSurvey(){
        String ccObject = Call_Card_Settings__c.getAll().values()[0].Call_Card_Object_ID__c;
        string retUrl;
        string accountName = EncodingUtil.urlEncode(selectedAccountName, 'UTF-8');
        retUrl = urlPrefix + '/apex/AdHocSurvey?id='+a.Id;
        return new PageReference(retURL);
    }
}