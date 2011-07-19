/*
 * This file is part of the  X2go Project - http://www.x2go.org
 * Copyright (C) 2011 Mike Gabriel <mike.gabriel@das-netzwerkteam.de> 
 * Copyright (C) 2011 Moritz 'Morty' Strübe <morty@gmx.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the
 * Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>
#include <errno.h>




int main( int argc, char *argv[] ) {
	char * x2gosqlitewrapper = NULL;
	size_t path_max;
	
/*
	The following snippet is taken from the realpath manpage
*/
#ifdef PATH_MAX
	path_max = PATH_MAX;
#else
	path_max = pathconf (".", _PC_PATH_MAX);
	if (path_max <= 0){
		path_max = 4096;
	}
#endif
	{
		// allocate dynamic buffer in stack: this needs C99 or gnu??
		char buffer[path_max];
		ssize_t rvrl;
		int rvap;

		// resolve link of /proc/self/exe to find out where we are
		rvrl = readlink("/proc/self/exe", buffer, path_max);
		if(rvrl == -1){
			perror("readlink(\"/proc/self/exe\",buffer,path_max)");
			exit(EXIT_FAILURE);
		}
		if(rvrl >= path_max){
			fprintf(stderr, "Could not resolve the path of this file using \"/proc/self/exe\". The path is to long (> %i)", path_max);
			exit(EXIT_FAILURE);
		}


		// derive the full path of x2gosqlitewrapper.pl from path of this binary
		rvap = asprintf(&x2gosqlitewrapper, "%s/%s", dirname(dirname(buffer)), "lib/x2go/x2gosqlitewrapper.pl");
		if(rvap == -1){
			fprintf(stderr, "Failed to allocate memory calling asprintf\n");
			exit(EXIT_FAILURE);
		}


		// execute the script, running with user-rights of this binary 
		execv(x2gosqlitewrapper, argv);

	}

	// ...fail
	fprintf(stderr, "Failed to execute %s: %s\n", x2gosqlitewrapper, strerror(errno));
	return EXIT_FAILURE;

}
