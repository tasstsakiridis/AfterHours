public class AccountLocation {
    public String city      { get; set; }
    public String country   { get; set; }
    public String latitude  { get; set; }
    public String longitude { get; set; }

    public AccountLocation() {
        init();
    }
    public AccountLocation(String city, String country) {
        init();

        this.city = city;
        this.country = country;
    }
    public AccountLocation(String city, String country, String latitude, String longitude) {
        init();

        this.city = city;
        this.country = country;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    void init() {
        this.city = '';
        this.country = '';
        this.latitude = '';
        this.longitude = '';
    }
}
