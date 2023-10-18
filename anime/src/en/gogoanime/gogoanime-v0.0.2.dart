import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MangaModel anime) async {
  final data = {"url": "${anime.baseUrl}/popular.html?page=${anime.page}"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res, '//*[@class="img"]/a/@href');

  anime.names = MBridge.xpath(res, '//*[@class="img"]/a/@title');

  anime.images = MBridge.xpath(res, '//*[@class="img"]/a/img/@src');

  return anime;
}

getLatestUpdatesAnime(MangaModel anime) async {
  final url =
      "https://ajax.gogo-load.com/ajax/page-recent-release-ongoing.html?page=${anime.page}&type=1";
  final data = {"url": url};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(
      res, '//*[@class="added_series_body popular"]/ul/li/a[1]/@href');

  anime.names = MBridge.xpath(
      res, '//*[//*[@class="added_series_body popular"]/ul/li/a[1]/@title');
  List<String> images = [];
  List<String> imagess = MBridge.xpath(res,
      '//*[//*[@class="added_series_body popular"]/ul/li/a/div[@class="thumbnail-popular"]/@style');
  for (var url in imagess) {
    images.add(url.replaceAll("background: url('", "").replaceAll("');", ""));
  }

  anime.images = images;

  return anime;
}

getAnimeDetail(MangaModel anime) async {
  final statusList = [
    {
      "Ongoing": 0,
      "Completed": 1,
    }
  ];

  final data = {"url": "${anime.baseUrl}${anime.link}"};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }

  final status = MBridge.xpath(
          res, '//*[@class="anime_info_body_bg"]/p[@class="type"][5]/text()')
      .first
      .replaceAll("Status: ", "");

  anime.description = MBridge.xpath(
          res, '//*[@class="anime_info_body_bg"]/p[@class="type"][2]/text()')
      .first
      .replaceAll("Plot Summary: ", "");

  anime.status = MBridge.parseStatus(status, statusList);
  anime.genre = MBridge.xpath(
          res, '//*[@class="anime_info_body_bg"]/p[@class="type"][3]/text()')
      .first
      .replaceAll("Genre: ", "")
      .split(",");

  final id = MBridge.xpath(res, '//*[@id="movie_id"]/@value').first;
  final urlEp =
      "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=4000&id=$id";
  final dataEp = {"url": urlEp};
  final resEp = await MBridge.http('GET', json.encode(dataEp));
  anime.urls = MBridge.xpath(resEp, '//*[@id="episode_related"]/li/a/@href');
  final names = MBridge.xpath(
      resEp, '//*[@id="episode_related"]/li/a/div[@class="name"]/text()');

  List<String> episodes = [];
  for (var a in names) {
    episodes.add("Episode ${MBridge.substringAfterLast(a, ' ')}");
  }

  anime.names = episodes;
  anime.chaptersDateUploads = [];
  return anime;
}

getVideoList(MangaModel anime) async {
  final datas = {"url": "${anime.baseUrl}${anime.link}"};

  final res = await MBridge.http('GET', json.encode(datas));

  if (res.isEmpty) {
    return [];
  }

  final serverUrls =
      MBridge.xpath(res, '//*[@class="anime_muti_link"]/ul/li/a/@data-video');
  final classNames =
      MBridge.xpath(res, '//*[@class="anime_muti_link"]/ul/li/@class');
  print(serverUrls);
  List<VideoModel> videos = [];
  for (var i = 0; i < classNames.length; i++) {
    final name = classNames[i];
    final url = serverUrls[i];
    print(url);
    List<VideoModel> a = [];
    if (name.contains("anime")) {
      a = await MBridge.gogoCdnExtractor(url);
    } else if (name.contains("vidcdn")) {
      a = await MBridge.gogoCdnExtractor(url);
    } else if (name.contains("doodstream")) {
      a = await MBridge.doodExtractor(url);
    } else if (name.contains("mp4upload")) {
      a = await MBridge.mp4UploadExtractor(url, null, "", "");
    } else if (name.contains("streamsb")) {
      // print("streamsb");
      // print(url);
    }
    for (var vi in a) {
      videos.add(vi);
    }
  }

  return videos;
}

searchAnime(MangaModel anime) async {
  final url =
      "${anime.baseUrl}/search.html?keyword=${anime.query}&page=${anime.page}";
  final data = {"url": url};
  final res = await MBridge.http('GET', json.encode(data));
  if (res.isEmpty) {
    return anime;
  }
  anime.urls = MBridge.xpath(res, '//*[@class="img"]/a/@href');

  anime.names = MBridge.xpath(res, '//*[@class="img"]/a/@title');

  anime.images = MBridge.xpath(res, '//*[@class="img"]/a/img/@src');
  return anime;
}