import 'package:dartchess/dartchess.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/common/time_increment.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/utils/json.dart';

part 'tournament.freezed.dart';

enum TournamentFreq {
  hourly,
  daily,
  eastern,
  weekly,
  weekend,
  monthly,
  shield,
  marathon,
  yearly,
  unique;

  static final IMap<String, TournamentFreq> nameMap = IMap(TournamentFreq.values.asNameMap());
}

typedef TournamentLists =
    ({
      IList<TournamentListItem> started,
      IList<TournamentListItem> created,
      IList<TournamentListItem> finished,
    });

typedef TournamentMe = ({int rank, GameFullId? gameId, bool? withdraw, Duration? pauseDelay});

const int kStandingsPageSize = 10;
typedef StandingPage = ({int page, IList<StandingPlayer> players});

extension TournamentExtension on Pick {
  TimeIncrement asTimeIncrementOrThrow() {
    final requiredPick = this.required();
    return TimeIncrement(
      requiredPick('limit').asIntOrThrow(),
      requiredPick('increment').asIntOrThrow(),
    );
  }

  TournamentFreq asTournamentFreqOrThrow() {
    final value = this.required().value;
    if (value is TournamentFreq) {
      return value;
    }
    if (value is String) {
      final freq = TournamentFreq.nameMap[value];
      if (freq != null) return freq;
    }
    throw PickException("value $value at $debugParsingExit can't be casted to TournamentFreq");
  }

  IList<TournamentListItem> asTournamentListOrThrow() =>
      asListOrThrow((pick) => TournamentListItem.fromServerJson(pick.asMapOrThrow())).toIList();

  Verdict asVerdictOrThrow() {
    final requiredPick = this.required();
    return (
      condition: requiredPick('condition').asStringOrThrow(),
      ok: requiredPick('verdict').asStringOrThrow() == 'ok',
    );
  }

  Verdicts asVerdictsOrThrow() {
    final requiredPick = this.required();
    return (
      list: requiredPick('list').asListOrThrow((pick) => pick.asVerdictOrThrow()).toIList(),
      accepted: requiredPick('accepted').asBoolOrThrow(),
    );
  }

  TournamentMe? asTournamentMeOrNull() {
    if (value == null) return null;
    try {
      final requiredPick = this.required();
      return (
        rank: requiredPick('rank').asIntOrThrow(),
        gameId: requiredPick('fullId').asGameFullIdOrNull(),
        withdraw: requiredPick('withdraw').asBoolOrNull(),
        pauseDelay: requiredPick('pauseDelay').asDurationFromSecondsOrNull(),
      );
    } catch (e) {
      return null;
    }
  }

  StandingPage? asStandingPageOrNull() {
    if (value == null) return null;
    try {
      final requiredPick = this.required();
      return (
        page: requiredPick('page').asIntOrThrow(),
        players:
            requiredPick(
              'players',
            ).asListOrThrow((pick) => _standingPlayerFromPick(pick.required())).toIList(),
      );
    } catch (_) {
      return null;
    }
  }

  FeaturedGame? asFeaturedGameOrNull() {
    if (value == null) return null;
    try {
      return _featuredGameFromPick(this.required());
    } catch (_) {
      return null;
    }
  }
}

@freezed
class TournamentListItem with _$TournamentListItem {
  const TournamentListItem._();

  const factory TournamentListItem({
    required TournamentId id,
    required String createdBy,
    required String fullName,
    required TimeIncrement timeIncrement,
    required bool rated,
    required Duration? timeToStart,
    required DateTime startsAt,
    required DateTime finishesAt,
    required int? maxRating,
    required int minutes,
    required int nbPlayers,
    required Perf perf,
    required int position,
    required TournamentFreq freq,
    required Variant variant,
    required LightUser? winner,
  }) = _TournamentListItem;

  factory TournamentListItem.fromServerJson(Map<String, Object?> json) =>
      _tournamentListItemFromPick(pick(json).required());
}

TournamentListItem _tournamentListItemFromPick(RequiredPick pick) {
  return TournamentListItem(
    id: pick('id').asTournamentIdOrThrow(),
    fullName: pick('fullName').asStringOrThrow(),
    timeIncrement: pick('clock').asTimeIncrementOrThrow(),
    rated: pick('rated').asBoolOrThrow(),
    createdBy: pick('createdBy').asStringOrThrow(),
    finishesAt: pick('finishesAt').asDateTimeFromMillisecondsOrThrow(),
    maxRating: pick('maxRating', 'rating').asIntOrNull(),
    minutes: pick('minutes').asIntOrThrow(),
    nbPlayers: pick('nbPlayers').asIntOrThrow(),
    perf: pick('perf').asPerfOrThrow(),
    position: pick('perf', 'position').asIntOrThrow(),
    freq: pick('schedule', 'freq').asTournamentFreqOrThrow(),
    timeToStart: pick('secondsToStart').asDurationFromSecondsOrNull(),
    startsAt: pick('startsAt').asDateTimeFromMillisecondsOrThrow(),
    variant: pick('variant').asVariantOrThrow(),
    winner: pick('winner').asLightUserOrNull(),
  );
}

typedef Verdicts = ({IList<Verdict> list, bool accepted});

typedef Verdict = ({String condition, bool ok});

@freezed
class Tournament with _$Tournament {
  const Tournament._();

  const factory Tournament({
    required TournamentId id,
    required String createdBy,
    required TimeIncrement timeIncrement,
    required Perf perf,
    required Variant variant,
    required bool berserkable,
    required FeaturedGame? featuredGame,
    required String fullName,
    required String? description,
    required bool? isFinished,
    required bool? isStarted,
    required Duration? timeToStart,
    required Duration? timeToFinish,
    required TournamentMe? me,
    required int nbPlayers,
    required StandingPage? standing,
    required Verdicts verdicts,
    required String? reloadEndpoint,
  }) = _Tournament;

  factory Tournament.fromServerJson(Map<String, Object?> json) =>
      _tournamentFromPick(pick(json).required());

  Tournament updateFromPartialServerJson(Map<String, Object?> json) =>
      _updateTournamentFromPartialPick(this, pick(json).required());
}

Tournament _tournamentFromPick(RequiredPick pick) {
  return Tournament(
    id: pick('id').asTournamentIdOrThrow(),
    createdBy: pick('createdBy').asStringOrThrow(),
    timeIncrement: pick('clock').asTimeIncrementOrThrow(),
    featuredGame: pick('featured').asFeaturedGameOrNull(),
    fullName: pick('fullName').asStringOrThrow(),
    description: pick('description').asStringOrNull(),
    isFinished: pick('isFinished').asBoolOrNull(),
    isStarted: pick('isStarted').asBoolOrNull(),
    timeToStart: pick('secondsToStart').asDurationFromSecondsOrNull(),
    timeToFinish: pick('secondsToFinish').asDurationFromSecondsOrNull(),
    me: pick('me').asTournamentMeOrNull(),
    nbPlayers: pick('nbPlayers').asIntOrThrow(),
    standing: pick('standing').asStandingPageOrNull(),
    perf: pick('perf').asPerfOrThrow(),
    variant: pick('variant').asVariantOrThrow(),
    berserkable: pick('berserkable').asBoolOrFalse(),
    verdicts: pick('verdicts').asVerdictsOrThrow(),
    reloadEndpoint: pick('reloadEndpoint').asStringOrNull(),
  );
}

Tournament _updateTournamentFromPartialPick(Tournament tournament, RequiredPick pick) {
  return tournament.copyWith(
    featuredGame: pick('featured').asFeaturedGameOrNull(),
    isFinished: pick('isFinished').asBoolOrNull(),
    isStarted: pick('isStarted').asBoolOrNull(),
    timeToStart: pick('secondsToStart').asDurationFromSecondsOrNull(),
    timeToFinish: pick('secondsToFinish').asDurationFromSecondsOrNull(),
    me: pick('me').asTournamentMeOrNull(),
    nbPlayers: pick('nbPlayers').asIntOrThrow(),
    standing: pick('standing').asStandingPageOrNull(),
  );
}

typedef StandingSheet = ({bool fire, IList<int> scores});

@freezed
class StandingPlayer with _$StandingPlayer {
  const StandingPlayer._();

  const factory StandingPlayer({
    required LightUser user,
    required int rating,
    required bool provisional,
    required int score,
    required StandingSheet sheet,
    required bool withdraw,
  }) = _StandingPlayer;
}

StandingPlayer _standingPlayerFromPick(RequiredPick pick) {
  return StandingPlayer(
    user: LightUser(
      id: UserId.fromUserName(pick('name').asStringOrThrow()),
      name: pick('name').asStringOrThrow(),
      title: pick('title').asStringOrNull(),
      flair: pick('flair').asStringOrNull(),
      isPatron: pick('patron').asBoolOrNull(),
    ),
    rating: pick('rating').asIntOrThrow(),
    provisional: pick('provisional').asBoolOrFalse(),
    score: pick('score').asIntOrThrow(),
    sheet: (
      fire: pick('sheet', 'fire').asBoolOrFalse(),
      scores:
          pick('sheet', 'scores').asStringOrThrow().characters.map((e) => int.parse(e)).toIList(),
    ),
    withdraw: pick('withdraw').asBoolOrFalse(),
  );
}

@freezed
class FeaturedPlayer with _$FeaturedPlayer {
  const FeaturedPlayer._();

  const factory FeaturedPlayer({
    required LightUser user,
    required int? rank,
    required bool? berserk,
  }) = _FeaturedPlayer;

  factory FeaturedPlayer.fromServerJson(Map<String, Object?> json) =>
      _featuredPlayerFromPick(pick(json).required());
}

FeaturedPlayer _featuredPlayerFromPick(RequiredPick pick) {
  return FeaturedPlayer(
    user: pick.asLightUserOrThrow(),
    rank: pick('rank').asIntOrNull(),
    berserk: pick('berserk').asBoolOrNull(),
  );
}

@freezed
class FeaturedGame with _$FeaturedGame {
  const FeaturedGame._();

  const factory FeaturedGame({
    required GameId id,
    required FeaturedPlayer white,
    required FeaturedPlayer black,
    required Side orientation,
    required String fen,
    required Move? lastMove,
    required bool? finished,
    required Side? winner,
  }) = _FeaturedGame;
}

FeaturedGame _featuredGameFromPick(RequiredPick pick) {
  return FeaturedGame(
    id: pick('id').asGameIdOrThrow(),
    white: FeaturedPlayer.fromServerJson(pick('white').asMapOrThrow()),
    black: FeaturedPlayer.fromServerJson(pick('black').asMapOrThrow()),
    orientation: pick('orientation').asSideOrThrow(),
    fen: pick('fen').asStringOrThrow(),
    lastMove: pick('lastMove').asUciMoveOrNull(),
    finished: pick('finished').asBoolOrNull(),
    winner: pick('winner').asSideOrNull(),
  );
}
