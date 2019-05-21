public with sharing class AfterHoursApp_Controller {
    public AfterHoursApp_Controller(ApexPages.StandardController controller) {
        
    }
    
    public PageReference redirect() {
		PageReference ref = Page.AccountsNearby;
        ref.getParameters().put('afterhours', '1');            
        return ref;
    }
}