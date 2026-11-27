class DetailedAnimeNews({
  required final String title,
  required final String postedOn,
  required final String postedBy,

  // Url to the image, if any
  required final String? image,

  // seperate by paragraphs, each paragraph is a string in the list
  required final List<String> info,
});
