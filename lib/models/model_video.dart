abstract class BaseSimpleVideoItemModel {
  late String title;
  String? bvid;
  int? cid;
  String? cover;
  int duration = -1;
  late BaseOwner owner;
  late BaseStat stat;
  String? coverBadge;

  void setCoverBadgeFromJson(Map<String, dynamic> json) {
    if (json['charging_pay']?['level'] != null ||
        json['is_charging_arc'] == true) {
      coverBadge = '充电专属';
      return;
    }

    if (json['badges'] case final List badges) {
      final text = badges
          .map((item) => item is Map ? item['text'] : null)
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .join('|');
      if (text.isNotEmpty) {
        coverBadge = text;
        return;
      }
    }

    final ugcPay = json['ugc_pay'];
    if (json['is_ugcpay'] == true ||
        ugcPay == true ||
        (ugcPay is num && ugcPay > 0)) {
      coverBadge = '会员视频';
    }
  }
}

abstract class BaseVideoItemModel extends BaseSimpleVideoItemModel {
  int? aid;
  String? desc;
  int? pubdate;
  bool isFollowed = false;
}

abstract class BaseOwner {
  int? mid;
  String? name;
}

abstract class BaseStat {
  int? view;
  int? like;
  int? danmu;
}

class Stat extends BaseStat {
  Stat.fromJson(Map<String, dynamic> json) {
    view = json["view"];
    like = json["like"];
    danmu = json['danmaku'];
  }
}

class PlayStat extends BaseStat {
  PlayStat.fromJson(Map<String, dynamic> json) {
    view = json['play'];
    danmu = json['danmaku'];
  }
}
