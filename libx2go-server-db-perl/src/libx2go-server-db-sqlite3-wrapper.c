/*
 * This file is part of the  X2Go Project - https://www.x2go.org
 * Copyright (C) 2011-2015 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
 * Copyright (C) 2011-2015 Moritz 'Morty' Strübe <morty@gmx.net>
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
 */

#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
	const char *x2gosqlitewrapper = TRUSTED_BINARY;

	argv[0] = "libx2go-server-db-sqlite3-wrapper.pl";
	// execute the script, running with user-rights of this binary
	int ret = execv(x2gosqlitewrapper, argv);
	int saved_errno = errno;

	if (ret) {
		fprintf (stderr, "unable to execute script '");
		fprintf (stderr, "%s", TRUSTED_BINARY);
		fprintf (stderr, "': ");
		fprintf (stderr, "%s", strerror (saved_errno));

		return (EXIT_FAILURE);
	}

	/* Should not be reached. */
	return (EXIT_SUCCESS);
}
