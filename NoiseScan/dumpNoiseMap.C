void dumpNoiseMap(long timestamp=-1, float thresh=0){

        o2::ccdb::CcdbApi api;
        api.init("http://localhost:8888");
        map<string, string> headers;
        map<std::string, std::string> filter;

        auto calib = api.retrieveFromTFileAny<o2::itsmft::NoiseMap>("MFT/Calib/NoiseMap/", filter , timestamp, &headers);
        calib->dumpAboveProbThreshold(thresh);

}
