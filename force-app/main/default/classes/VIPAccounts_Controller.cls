global with sharing class VIPAccounts_Controller {
    @AuraEnabled(cacheable=true)
    global static List<VIP_Accounts__c> getVIPAccounts(List<String> fields, Decimal latitude, Decimal longitude) {
        String soql = 'SELECT ';
        for(String s : fields) {
            soql += s + ',';
        }
        soql.removeEnd(',');

        soql += ' FROM VIP_Accounts__c';
        soql += ' WHERE DISTANCE(GEOLOCATION(Latitude__c, Longitude__c), GEOLOCATION(' + latitude + ',' + longitude + '), "km") < 50';
        soql += ' ORDER BY Account__r.Name';

        return Database.query(soql);
    }
}
