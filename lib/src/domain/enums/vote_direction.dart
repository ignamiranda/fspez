enum VoteDirection {
  upvote(1),
  downvote(-1),
  none(0);

  final int value;
  const VoteDirection(this.value);
}
