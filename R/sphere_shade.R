#'@title sphere_shade
#'
#'@description Calculates local shadow map for a elevation matrix by calculating the dot 
#'product between light direction and the surface normal vector at that point. Each point's
#'intensity is proportional to the cosine of the normal ve
#'
#'@param heightmap A two-dimensional matrix, where each entry in the matrix is the elevation at that point. All points are assumed to be evenly spaced.
#'@param sunangle Default `315` (NW). The direction of the main highlight color (derived from the built-in palettes or the `create_texture` function).
#'@param texture Default `imhof1`. Either a square matrix indicating the spherical texture mapping, or a string indicating one 
#'of the built-in palettes (`imhof1`,`imhof2`,`imhof3`,`imhof4`,`desert`, `bw`, and `unicorn`). 
#'@param normalvectors Default `NULL`. Cache of the normal vectors (from `calculate_normal` function). Supply this to speed up texture mapping.
#'@param zscale Default `1`. The ratio between the x and y spacing (which are assumed to be equal) and the z axis. 
#'@param progbar Default `TRUE` if interactive, `FALSE` otherwise. If `FALSE`, turns off progress bar.
#'@return RGB array of hillshaded texture mappings.
#'@export
#'@examples
#'plot_map(sphere_shade(volcano,texture="desert"))
sphere_shade = function(heightmap, sunangle=315, texture="imhof1", normalvectors = NULL, zscale=1, progbar = interactive()) {
  sunangle = sunangle/180*pi
  flipud = function(x) {
    x[,ncol(x):1]
  }
  if(is.null(normalvectors)) {
    normalvectors = calculate_normal(heightmap = heightmap, zscale = zscale, progbar = progbar)
  } 
  heightmap = add_padding(heightmap)
  if(class(texture) == "character") {
    if(texture %in% c("imhof1","imhof2","imhof3","imhof4","desert","bw","unicorn")) {
      if(texture == "imhof1") {
        texture = create_texture("#fff673","#55967a","#8fb28a","#55967a","#cfe0a9")
      } else if(texture == "imhof2") {
        texture = create_texture("#f5dfca","#63372c","#dfa283","#195f67","#83a6a0")
      } else if(texture == "imhof3") {
        texture = create_texture("#e9e671","#7f3231","#cbb387","#607080","#7c9695")
      } else if(texture == "imhof4") {
        texture = create_texture("#ffe3b3","#66615e","#f1c3a9","#ac9988","#abaf98")
      } else if(texture == "bw") {
        texture = create_texture("white","black","grey75","grey25","grey50")
      } else if(texture == "desert") {
        texture = create_texture("#ffe3b3","#6a463a","#dbaf70","#9c9988","#c09c7c")
      } else if(texture == "unicorn") {
        texture = create_texture("red","green","blue","yellow","white")
      } 
    } else {
      stop("Built-in texture palette not recognized: possible choices are `imhof1`,`imhof2`,`imhof3`,`imhof4`,`bw`,`desert`, and `unicorn`")
    }
  }
  center = dim(texture)[1:2]/2
  heightmap = flipud(t(heightmap)) / zscale
  distancemat = (1 - normalvectors[["z"]]) * center[1]
  lengthmat = sqrt(1 - (normalvectors[["z"]])^2)
  image_x_nocenter = ((-normalvectors[["x"]] / lengthmat * distancemat) )
  image_y_nocenter = ((normalvectors[["y"]] / lengthmat * distancemat) )
  image_x = floor(cos(sunangle)*image_x_nocenter - sin(sunangle)*image_y_nocenter) + center[1]
  image_y = floor(sin(sunangle)*image_x_nocenter + cos(sunangle)*image_y_nocenter) + center[2]
  image_x[is.na(image_x)] = center[1]
  image_y[is.na(image_y)] = center[2]
  image_x[is.nan(image_x)] = center[1]
  image_y[is.nan(image_y)] = center[2]
  image_x[is.infinite(image_x)] = center[1]
  image_y[is.infinite(image_y)] = center[2]
  image_x[image_x > dim(texture)[1]] = dim(texture)[1]
  image_y[image_y > dim(texture)[2]] = dim(texture)[2]
  image_x[image_x == 0] = 1
  image_y[image_y == 0] = 1
  returnimage = array(dim=c(nrow(heightmap),ncol(heightmap),3))
  returnimage[,,1] = construct_matrix(texture[,,1],nrow(heightmap),ncol(heightmap), image_x, image_y)
  returnimage[,,2] = construct_matrix(texture[,,2],nrow(heightmap),ncol(heightmap), image_x, image_y)
  returnimage[,,3] = construct_matrix(texture[,,3],nrow(heightmap),ncol(heightmap), image_x, image_y)
  returnimageslice = array(dim=c(nrow(heightmap)-2,ncol(heightmap)-2,3))
  returnimageslice[,,1] = returnimage[c(-1,-nrow(heightmap)),c(-1,-ncol(heightmap)),1]
  returnimageslice[,,2] = returnimage[c(-1,-nrow(heightmap)),c(-1,-ncol(heightmap)),2]
  returnimageslice[,,3] = returnimage[c(-1,-nrow(heightmap)),c(-1,-ncol(heightmap)),3]
  return(returnimageslice)
}
